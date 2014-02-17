function impasse_loading_options() {
    return {
	message: '<span>loading...</span>',
	css: {
	    backgroundPosition: "0% 40%",
	    backgroundRepeat: "no-repeat",
	    paddingLeft: "26px",
	    backgroundColor: "#EEE",
	    border: "1px solid #BBB",
	    top: "35%",
	    left: "40%",
	    width: "20%",
	    fontWeight: "bold",
	    textAlign: "center",
	    padding: "0.6em",
	    opacity: 0.9,
	    cursor: "auto"
	}
    };
}
function ajax_error_handler(xhr, status ,ex) {
    var message = "Can't connect. reasons %{value}".replace('%{value}', ex);
    if (xhr.status == 401 || xhr.status == 403) {
	message = "Unauthorized!";
    }
    show_notification_dialog('error', message);
}

function show_notification_dialog(type, message) {
    noty({
	text: message,
        theme: 'noty_theme_twitter',
	timeout: 2000,
	type: type
    });
}

(function($) {
    $.ajaxSetup({
        beforeSend: function(req) {
	    var csrf_meta_tag = jQuery("meta[name=csrf-token]");
            if (csrf_meta_tag.size() > 0) {
	        req.setRequestHeader("X-CSRF-Token", csrf_meta_tag.attr("content"));
	    }
        }
    });

    $.fn.floatmenu = function(options) {
	return this.each(function() {
	    var $this = $(this);
	    var menuPosition = $this.offset().top;
	    $this.css({zIndex: 10});

/* 	    $(window).scroll(function(e) {
		var offsetTop = $(window).scrollTop() - menuPosition;
		if(offsetTop > 0) {
		    $this.css({position: "absolute", top: offsetTop});
		} else {
		    $this.css("position", "static");
		}
	    });
 */	});
    }
})(jQuery);

