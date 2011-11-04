#!/usr/bin/env jruby
# -*- coding: utf-8 -*-
require 'rubygems'
require 'webrick'
require 'webrick/httpproxy'
require 'digest/sha2'
require 'nokogiri'
require 'addressable/uri'
require 'css_parser'

require File.expand_path('../../../../../config/boot',  __FILE__)
require File.expand_path("#{RAILS_ROOT}/config/environment",  __FILE__)

dbconfig = YAML.load_file("#{RAILS_ROOT}/config/database.yml")['development']
ActiveRecord::Base.establish_connection(dbconfig)

include WEBrick


class HtmlContext
  def initialize(req, res)
    # TODO SSL
    @host = "http://#{req.host}:#{req.port}"
    @path = (req.path.end_with? '/') ? req.path : req.path[0,req.path.rindex("/")+1]
    @doc = Nokogiri::HTML.parse(res.body)
    @resources = {"image"=>{}, 'css'=>{}, 'js'=>{}}

    @doc.search('link[href]').each do |css|
      @resources['css'][get_fqdn(css['href'])] = css
    end

    @doc.search('script[src]').each do |js|
      @resources['js'][get_fqdn(js['src'])] = js
    end

    @doc.search('*[style*="background-image"]').each do |elm|
      ruleset = CssParser::RuleSet.new(nil, elm['style'])
      if /url\(\"?(.*?)\"?\)/ =~ ruleset['background-image']
        @resources['image'][get_fqdn($1)] = elm
      end
    end

    @doc.search('img').each do |img|
      @resources['image'][get_fqdn(img['src'])] = img
    end
    @request_hash = Digest::SHA256.hexdigest(req.to_s)
  end

  def fetch_asset(type, uri, digest)
     asset = @resources[type][uri]
     unless asset.nil?
       if asset.name == 'img'
         asset['src'] = "../images/#{digest}"
       elsif !asset['style'].nil?
         ruleset = CssParser::RuleSet.new(nil, asset['style'])
         ruleset['background-image'] = ruleset['background-image'].sub(/url(\(\"?(.*?)\"?\))/, "url(../images/#{digest})")
         asset['style'] = ruleset.to_s
       end
     end
  end

  def save
    File.open("html/#{@request_hash}", "w") {|f|
      f << @doc.to_html
    }
  end

  private
  def get_fqdn(path)
    path = Addressable::URI.parse(path)
    if !path.scheme.nil?
      path.normalize.to_s
    elsif path.to_s[0] == '/'[0]
      Addressable::URI.parse(@host+path.to_s).normalize.to_s
    else
      Addressable::URI.parse(@host+@path+path.to_s).normalize.to_s
    end
  end
end

class TestGatewayServer < HTTPProxyServer
  attr_accessor :current_html

  def proxy_service(req, res)
    req.header.delete('accept-encoding')
    req.header.delete('if-modified-since')

    super

    # If no contents, don't record.
    return if 300 <= res.status and res.status < 400

    content_type = res.content_type || '' 
    digest = Digest::SHA256.hexdigest(req.to_s)
    dir = if content_type.start_with? 'text/html' or req.path.end_with? '.html'
            unless @current_html.nil?
              @current_html.save
            end
            @current_html = HtmlContext.new(req,res)
            'html'
          elsif content_type.start_with? 'image/' or /\.(png|gif|jpg|jpeg)$/ =~ req.path
            @current_html.fetch_asset('image', req.request_uri.to_s, digest)
            'images'
          elsif content_type.start_with? 'text/css' or req.path.end_with? '.css'
            @current_html.fetch_asset('css', req.request_uri.to_s, digest)
            'stylesheets'
          elsif content_type.start_with? 'text/javascript' or req.path.end_with? '.js'
            @current_html.fetch_asset('js', req.request_uri.to_s, digest)
            'javascripts'
          else
            'others'
          end

    File.open("meta/#{digest}", "w") {|f|
      f << "[request]\n"
      f << req.to_s
      f << "[response]\n"
      f << res.header.map{|e| "#{e[0]}: #{e[1]}" }.join("\n")
    }
    File.open("#{dir}/#{digest}", "w") {|f|
      f << res.body
    }
  end
end

module TestGateway
  class ControllServlet < HTTPServlet::AbstractServlet
    def initialize(server, proxy)
      super(server)
      @proxy = proxy
    end
    def do_GET(req, res)
      if req.query_string == 'start'
        Thread.new do
          @proxy.start
        end
        res['Content-Type'] = 'text/plain'
        res.body = 'started'
      elsif req.query_string == 'stop'
        @proxy.stop
        res['Content-Type'] = 'text/plain'
        res.body = 'stoped'
      else
        res['Content-Type'] = 'text/plain'
        res.body = @proxy.status.to_s
      end
    end
  end
end

begin
  Dir.mkdir("meta")
  Dir.mkdir("html")
  Dir.mkdir("images")
  Dir.mkdir("javascripts")
  Dir.mkdir("stylesheets")
  Dir.mkdir("others")
rescue
end
Dir.glob("meta/*"){|f| File.delete(f) }
Dir.glob("html/*"){|f| File.delete(f) }
Dir.glob("images/*"){|f| File.delete(f) }
Dir.glob("javascripts/*"){|f| File.delete(f) }
Dir.glob("stylesheets/*"){|f| File.delete(f) }
Dir.glob("others/*"){|f| File.delete(f) }

s = TestGatewayServer.new({
	:Port => 3128,
	:ProxyVia => false,
	:ProxyAuthProc => Proc.new() {|req, res|
		WEBrick::HTTPAuth.proxy_basic_auth(req, res, 'proxy') { |user, pass|
                        user = User.try_to_login(user, pass)
                        !(user.nil? or user.new_record?)
		}
	}
})

controll_port = WEBrick::HTTPServer.new({ :Port => 3129 })
controll_port.mount('/', TestGateway::ControllServlet, s)
trap(["INT","TERM"]){ controll_port.shutdown }
controll_port.start

