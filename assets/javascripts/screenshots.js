/*!
 * Tiny Carousel 1.9
 * http://www.baijs.nl/tinycarousel
 *
 * Copyright 2010, Maarten Baijs
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://www.opensource.org/licenses/mit-license.php
 * http://www.opensource.org/licenses/gpl-2.0.php
 *
 * Date: 01 / 06 / 2011
 * Depends on library: jQuery
 */
 
(function($){
    $.tiny = $.tiny || { };
    
    $.tiny.carousel = {
	options: {
	    start: 1, // where should the carousel start?
	    display: 1, // how many blocks do you want to move at 1 time?
	    axis: 'x', // vertical or horizontal scroller? ( x || y ).
	    controls: true, // show left and right navigation buttons.
	    pager: false, // is there a page number navigation present?
	    interval: false, // move to another block on intervals.
	    intervaltime: 3000, // interval time in milliseconds.
	    rewind: false, // If interval is true and rewind is true it will play in reverse if the last slide is reached.
	    animation: true, // false is instant, true is animate.
	    duration: 1000, // how fast must the animation move in ms?
	    callback: null // function that executes after every move.
	}
    };
    
    $.fn.tinycarousel = function(options) {
	var options = $.extend({}, $.tiny.carousel.options, options);
	this.each(function(){ $(this).data('tcl', new Carousel($(this), options)); });
	return this;
    };
    $.fn.tinycarousel_start = function(){ $(this).data('tcl').start(); };
    $.fn.tinycarousel_stop = function(){ $(this).data('tcl').stop(); };
    $.fn.tinycarousel_move = function(iNum){ $(this).data('tcl').move(iNum-1,true); };
    
    function Carousel(root, options){
	var oSelf = this;
	var oViewport = $('.viewport:first', root);
	var oContent = $('.overview:first', root);
	var oPages = oContent.children();
	var oBtnNext = $('.next:first', root);
	var oBtnPrev = $('.prev:first', root);
	var oPager = $('.pager:first', root);
	var iPageSize, iSteps, iCurrent, oTimer, bPause, bForward = true, bAxis = options.axis == 'x';
	
	function initialize(){
	    iPageSize = bAxis ? $(oPages[0]).outerWidth(true) : $(oPages[0]).outerHeight(true);
	    var iLeftover = Math.ceil(((bAxis ? oViewport.outerWidth() : oViewport.outerHeight()) / (iPageSize * options.display)) -1);
	    iSteps = Math.max(1, Math.ceil(oPages.length / options.display) - iLeftover);
	    iCurrent = Math.min(iSteps, Math.max(1, options.start)) -2;
	    oContent.css(bAxis ? 'width' : 'height', (iPageSize * oPages.length));
	    oSelf.move(1);
	    setEvents();
	    return oSelf;
	};
	function setEvents(){
	    if(options.controls && oBtnPrev.length > 0 && oBtnNext.length > 0){
		oBtnPrev.click(function(){oSelf.move(-1); return false;});
		oBtnNext.click(function(){oSelf.move( 1); return false;});
	    }
	    if(options.interval){ root.hover(oSelf.stop,oSelf.start); }
	    if(options.pager && oPager.length > 0){ $('a',oPager).click(setPager); }
	};
	function setButtons(){
	    if(options.controls){
		oBtnPrev.toggleClass('disable', !(iCurrent > 0));
		oBtnNext.toggleClass('disable', !(iCurrent +1 < iSteps));
	    }
	    if(options.pager){
		var oNumbers = $('.pagenum', oPager);
		oNumbers.removeClass('active');
		$(oNumbers[iCurrent]).addClass('active');
	    }
	};
	function setPager(oEvent){
	    if($(this).hasClass('pagenum')){ oSelf.move(parseInt(this.rel), true); }
	    return false;
	};
	function setTimer(){
	    if(options.interval && !bPause){
		clearTimeout(oTimer);
		oTimer = setTimeout(function(){
		    iCurrent = iCurrent +1 == iSteps ? -1 : iCurrent;
		    bForward = iCurrent +1 == iSteps ? false : iCurrent == 0 ? true : bForward;
		    oSelf.move(bForward ? 1 : -1);
		}, options.intervaltime);
	    }
	};
	this.stop = function(){ clearTimeout(oTimer); bPause = true; };
	this.start = function(){ bPause = false; setTimer(); };
	this.move = function(iDirection, bPublic){
	    iCurrent = bPublic ? iDirection : iCurrent += iDirection;
	    if(iCurrent > -1 && iCurrent < iSteps){
		var oPosition = {};
		oPosition[bAxis ? 'left' : 'top'] = -(iCurrent * (iPageSize * options.display));
		oContent.animate(oPosition,{
		    queue: false,
		    duration: options.animation ? options.duration : 0,
		    complete: function(){
			if(typeof options.callback == 'function')
			    options.callback.call(this, oPages[iCurrent], iCurrent);
		    }
		});
		setButtons();
		setTimer();
	    }
	};
	this.refresh = function() {
	    if (iPageSize == null)
		iPageSize = bAxis ? $(oPages[0]).outerWidth(true) : $(oPages[0]).outerHeight(true);
	    oPages = oContent.children();
            var iLeftover = Math.ceil(((bAxis ? oViewport.outerWidth() : oViewport.outerHeight()) / (iPageSize * options.display ) -1));
            iSteps = Math.max(1, Math.ceil(oPages.length / options.display) - iLeftover);
	    oContent.css(bAxis ? 'width' : 'height', (iPageSize * oPages.length));
	    setButtons();
	    if (iCurrent >= iSteps) oSelf.move(-1);
	}
	return initialize();
    };
})(jQuery);

/*
 * JavaScript Canvas to Blob 2.0.3
 * https://github.com/blueimp/JavaScript-Canvas-to-Blob
 *
 * Copyright 2012, Sebastian Tschan
 * https://blueimp.net
 *
 * Licensed under the MIT license:
 * http://www.opensource.org/licenses/MIT
 *
 * Based on stackoverflow user Stoive's code snippet:
 * http://stackoverflow.com/q/4998908
 */
(function (window) {
    'use strict';
    var CanvasPrototype = window.HTMLCanvasElement &&
            window.HTMLCanvasElement.prototype,
        hasBlobConstructor = window.Blob && (function () {
            try {
                return Boolean(new Blob());
            } catch (e) {
                return false;
            }
        }()),
        hasArrayBufferViewSupport = hasBlobConstructor && window.Uint8Array &&
            (function () {
                try {
                    return new Blob([new Uint8Array(100)]).size === 100;
                } catch (e) {
                    return false;
                }
            }()),
        BlobBuilder = window.BlobBuilder || window.WebKitBlobBuilder ||
            window.MozBlobBuilder || window.MSBlobBuilder,
        dataURLtoBlob = (hasBlobConstructor || BlobBuilder) && window.atob &&
            window.ArrayBuffer && window.Uint8Array && function (dataURI) {
                var byteString,
                    arrayBuffer,
                    intArray,
                    i,
                    mimeString,
                    bb;
                if (dataURI.split(',')[0].indexOf('base64') >= 0) {
                    // Convert base64 to raw binary data held in a string:
                    byteString = atob(dataURI.split(',')[1]);
                } else {
                    // Convert base64/URLEncoded data component to raw binary data:
                    byteString = decodeURIComponent(dataURI.split(',')[1]);
                }
                // Write the bytes of the string to an ArrayBuffer:
                arrayBuffer = new ArrayBuffer(byteString.length);
                intArray = new Uint8Array(arrayBuffer);
                for (i = 0; i < byteString.length; i += 1) {
                    intArray[i] = byteString.charCodeAt(i);
                }
                // Separate out the mime component:
                mimeString = dataURI.split(',')[0].split(':')[1].split(';')[0];
                // Write the ArrayBuffer (or ArrayBufferView) to a blob:
                if (hasBlobConstructor) {
                    return new Blob(
                        [hasArrayBufferViewSupport ? intArray : arrayBuffer],
                        {type: mimeString}
                    );
                }
                bb = new BlobBuilder();
                bb.append(arrayBuffer);
                return bb.getBlob(mimeString);
            };
    if (window.HTMLCanvasElement && !CanvasPrototype.toBlob) {
        if (CanvasPrototype.mozGetAsFile) {
            CanvasPrototype.toBlob = function (callback, type) {
                callback(this.mozGetAsFile('blob', type));
            };
        } else if (CanvasPrototype.toDataURL && dataURLtoBlob) {
            CanvasPrototype.toBlob = function (callback, type) {
                callback(dataURLtoBlob(this.toDataURL(type)));
            };
        }
    }
    if (typeof define === 'function' && define.amd) {
        define(function () {
            return dataURLtoBlob;
        });
    } else {
        window.dataURLtoBlob = dataURLtoBlob;
    }
}(this));

/**
 * Based on pasteboard (https://github.com/JoelBesada/pasteboard)
 *
 * MIT Licensed (http://www.opensource.org/licenses/mit-license.php)
 * Copyright 2012, Joel Besada
 */
var pasteboard = {};
(function($) {
    function fileHandler(pasteboard) {
	var FILE_SIZE_LIMIT = 5 * 1024 * 1024;

	function checkFileSize(file, action) {
	    if (file.size > FILE_SIZE_LIMIT) {
		$(pasteboard).trigger("filetoolarge", { size: file.size, action: action});
		return false;
	    }
	    return true;
	}

	this.isSupported = function() {
	    return !!(window.FileReader || window.URL || window.webkitURL);
	}
	this.readFile = function(file, action) {
	    var currentFile = file;
	    if (checkFileSize(currentFile, action)) {
		var url = window.URL || window.webkitURL;
		if (url) {
		    var objectURL = url.createObjectURL(file);
		    if (typeof objectURL === 'string') {
			$(pasteboard).trigger("imageinserted", {image: objectURL, action: action, size: currentFile.size});
			return;
		    }
		}
	    }
	};
	this.readData = function(data, action) {
	    var currentFile = dataURLtoBlob(data);
	    if (checkFileSize(currentFile)) {
		$(pasteboard).trigger("imageinserted", {
		    image: data, action: action, size: currentFile.size
		});
	    }
	};

	this.uploadFile = function(cropSettings, callback) {
	    var canvas = $('<canvas width="'+ cropSettings.w +'" height="'+ cropSettings.h +'"/>');
	    var ctx = canvas[0].getContext("2d");
	    ctx.drawImage(pasteboard.imageEditor.getImage(), cropSettings.x, cropSettings.y, cropSettings.w, cropSettings.h, 0, 0, cropSettings.w, cropSettings.h);
	    var newImage = new Image();
	    newImage.src = canvas[0].toDataURL();
	};

    }

    function dragAndDrop(pasteboard) {
	var $body = $("body");
	var $dropArea = $('<div class="drop-area" style="position:absolute; top: 15px; z-index: 2000; width: 100%; height: 100%"/>');

	function onDragStart(e) {
	    $body.addClass("dragging");
	}

	function onDragEnd(e) {
	    $body.removeClass("dragging");
	}

	function onDragOver(e) {
	    e.stopPropagation();
	    e.preventDefault();
	    e.originalEvent.dataTransfer.dropEffect = 'copy';
	}

	function onDragDrop(e) {
	    e.stopPropagation();
	    e.preventDefault();
	    $body.removeClass("dragging");

	    var files = e.originalEvent.dataTransfer.files;
	    for (var i=0; i < files.length; i++) {
		if (files[i].type.match(/image/)) {
		    pasteboard.fileHandler.readFile(files[i], "Drag and Drop");
		    return;
		}
	    }
	    $(pasteboard).trigger("noimagefound", { drop: true });
	}

	this.isSupported = function() {
	    return pasteboard.fileHandler.isSupported();
	};

	this.init = function() {
	    $body.prepend($dropArea);
	    $dropArea.bind({
		"dragenter.dragevent": onDragStart,
		"dragleave.dragevent": onDragEnd,
		"dragover.dragevent": onDragOver,
		"drop.dragevent": onDragDrop
	    });
	};

	this.hide = function() {
	    $dropArea.unbind(".dragevent");
	    $dropArea.detach();
	}
    }

    function copyAndPaste(pasteboard) {
	var pasteArea = $('<div contenteditable="" style="opacity:0;"/>');
	function onPaste(e) {
	    if (e.originalEvent.clipboardData) {
		var items = e.originalEvent.clipboardData.items;
		if (items == null) {
		    $("html").addClass("no-copyandpaste");
		    return;
		}
		for (var i=0; i < items.length; i++) {
		    if (items[i].type.match(/image/)) {
			pasteboard.fileHandler.readFile(items[i].getAsFile(), "Copy and Paste");
			return;
		    }
		}
		$(pasteboard).trigger("noimagefound", {paste: true});
	    } else {
		setTimeout(parsePaste, 1);
	    }
	}

	function parsePaste() {
	    var child = pasteArea[0].childNodes[0];
	    pasteArea.html("");
	    if (child) {
		if (child.tagName == "IMG" && child.src.match(/^data:image/i)) {
		    pasteboard.fileHandler.readData(child.src, "Copy and Paste");
		    return;
		}
	    }
	    $(pasteboard).trigger("noimagefound", { paste: true });
	}

	function focusPasteArea() {
	    pasteArea.focus();
	}

	this.isSupported = function() {
	    return typeof(document.onpaste) != "undefined";
	};

	this.init = function() {
	    if (!window.Clipboard) {
		pasteArea.appendTo(pasteboard.overlay).focus();
		$(document).bind("click", focusPasteArea);
	    }
	    $(window).bind("paste", onPaste);
	};

	this.hide = function() {
	    pasteArea.remove();
	    $(window).unbind("paste", onPaste);
	    $(document).unbind("click", focusPasteArea);
	};
    }

    function imageEditor(pasteboard) {
	var $imageEditor = null;
	var $image = null;
	var scale = 1.0;
	var cropArea = { x:0, y:0, w:0, h:0 };
	var imageSize = { w: 640, h: 480 };
	var uploadImageCallback = null;

	function updateCoords(c) {
	    cropArea = c;
	}

	function setPosition() {
	    var y = $(window).height() / 2 - $imageEditor.outerHeight() / 2;
	    if ($(imageEditor).outerHeight() > $(window).height())
		y=0;
	    $imageEditor.css("top", y);
	    var x = Math.max($(window).width() / 2 - $imageEditor.outerWidth() / 2, 0);
	    $imageEditor.css("left", x);
	}

	function addEvents() {
	    var self = this;
	    $(window).bind("resize.imageeditorevent", function() {
		setPosition();
	    });
	    $(".image-editor .upload").live("click.imageeditorevent", function() {
		$(self).trigger("upload");
	    });
	    $(".image-editor .cancel").live("click.imageeditorevent", function() {
		$(self).trigger("cancel");
	    });
	}

	function removeEvents() {
	    $(window).unbind(".imageeditorevent");
	}

	function loadImage(img) {
	    var image = new Image();
	    image.src = img;
	    image.onload = function() {
		scale = Math.min(imageSize.w / image.width, imageSize.h / image.height);
		if (scale > 1.0) scale = 1.0;
		$imageEditor = $('<div class="image-editor"/>').css({position: "absolute"}).appendTo(pasteboard.overlay);
		$(image).appendTo($imageEditor).Jcrop({
		    onSelect: updateCoords, bgColor: 'transparent',
		    boxWidth: image.width * scale, boxHeight: image.height * scale
		});
		var actionBar = $('<div class="action-bar"><button class="cancel">Delete</button><button class="upload">Upload</button></div>');
		actionBar.appendTo($imageEditor);
		setPosition();
		cropArea.w = $(image).width();
		cropArea.h = $(image).height();
	    };
	}
	this.init = function(img) {
	    loadImage(img);
	    addEvents.call(this);
	};
	this.hide = function(callback) {
	    removeEvents();
	    if ($imageEditor == null)
		return;
	    $imageEditor.fadeOut(500, function() {
		$imageEditor.remove();
		if (callback) callback();
	    });
	};
	this.uploadImage = function(callback) {
	    var canvas = $('<canvas width="'+ cropArea.w +'" height="'+ cropArea.h +'"/>');
	    var ctx = canvas[0].getContext("2d");
	    ctx.drawImage(pasteboard.imageEditor.getImage(),
			  cropArea.x, cropArea.y, cropArea.w, cropArea.h, 0, 0, cropArea.w, cropArea.h);
	    if (uploadImageCallbackFunc != null) {
		var newImage = new Image();
		newImage.src = canvas[0].toDataURL();
		newImage.onload = function() {
		    uploadImageCallbackFunc.call(this, newImage);
		    callback.call();
		}
	    } else {
		callback.call();
	    }
	};
	this.uploadImageCallback = function(callback) {
	    uploadImageCallbackFunc = callback;
	};
	this.getImage = function() {
	    return $imageEditor.find("img")[2];
	};
	this.getScale = function() {
	    return scale;
	}
    }

    function appFlow(pasteboard) {
	var cropArea = { x:0, y:0, w:0, h:0};

	var states = {
	    initializing: 0,
	    insertingImage: 1,
	    editingImage: 2,
	    uploadingImage: 3,
	    generatingLink: 4
	};
	var openDialog = null;

	var $pasteboard = $(pasteboard);

	function setState(state, stateData) {
	    if (!stateData) stateData = {};

	    switch (state) {
	    case states.initializing:
		openDialog = $(".ui-dialog-content").filter(function() {
		    return $(this).parents(".ui-dialog").is(":not(:hidden)");
		});
		openDialog.dialog("close");
		$("#pasteboard .pasteboard-close").one("click", function() {
		    pasteboard.dragAndDrop.hide();
		    pasteboard.copyAndPaste.hide();		    
		    $(pasteboard).unbind(".stateevents");
		    $(pasteboard.imageEditor).unbind(".stateevents");
		    pasteboard.imageEditor.hide();
		    pasteboard.overlay.remove();
		    openDialog.dialog("open");
		});

		setState(++state);
		break;
	    case states.insertingImage:
		pasteboard.dragAndDrop.init();
		pasteboard.copyAndPaste.init();
		$(".splash").show();

		$pasteboard.bind("imageinserted.stateevents", function(e, eventData) {
		    $pasteboard.unbind(".stateevents");
		    setState(++state, {image: eventData.image});
		});
		$pasteboard.bind("filetoolarge.stateevents", function(e, eventData) {
		    alert("The file size of the image you are trying to ");
		});
		$pasteboard.bind("noimagefound.stateevents", function(e, eventData) {
		    var content = "No image found"
		    if (eventData.paste)
			content = "No image data was found in your clipboard,"
			+ "copy an image first (or take a screenshot).";
		    else if (eventData.drop)
			content = "The oject you dragged in is not an image file."
		    alert(content);
			
		});
		break;
	    case states.editingImage:
		pasteboard.dragAndDrop.hide();
		pasteboard.copyAndPaste.hide();
		$(".splash").hide();
		pasteboard.imageEditor.init(stateData.image);

		$(pasteboard.imageEditor).bind("cancel.stateevents", function(e) {
		    $(pasteboard.imageEditor).unbind(".stateevents");
		    pasteboard.imageEditor.hide(function() {
			setState(--state);
		    });
		});

		$(pasteboard.imageEditor).bind("upload.stateevents", function(e) {
		    $(pasteboard.imageEditor).unbind(".stateevents");
		    pasteboard.imageEditor.uploadImage(function(upload) {
			setState(++state, {upload: upload});
		    });
		});
		break;
	    case states.uploadingImage:
		pasteboard.imageEditor.hide();
		var confirm = $("<div><p>Do you upload another files?<p></div>")
		    .append($('<button>Yes</botton>').one("click", function(e) {
			confirm.remove(); setState(1)
		    }))
		    .append($('<button>No</botton>')).one("click", function(e) {
			confirm.remove();
			pasteboard.overlay.remove();
			openDialog.dialog("open");
		    })
		    .appendTo(pasteboard.overlay);
		break;
	    }
	}

	this.start = function() {
	    setState(0);
	};
    }

    $(".screenshot-thumbnail").live("click", function(e) {
	var overlay = $("<div/>").css({
	    position: 'fixed', top:0, left: 0, zIndex: 2000, backgroundColor: 'rgba(0,0,0,0.3)',
	    width: '100%', height: '100%'
	}).appendTo("body");
	var rawImage = new Image();
	rawImage.src = $("img", this).attr("src").replace(/.s.png$/, ".png");
	rawImage.onload = function() {
	    $(rawImage).css({position: 'relative',
			     top: Math.max(($(window).height() - rawImage.height) / 2, 0),
			     left: Math.max(($(window).width() - rawImage.width) / 2, 0),
			     zIndex: 1000}).appendTo(overlay);
	    overlay.one("click", function() { overlay.remove() });
	}
    });

    $(document).ready(function($) {
	pasteboard['overlay'] = $("body");
	pasteboard['dragAndDrop'] = new dragAndDrop(pasteboard);
	pasteboard['copyAndPaste'] = new copyAndPaste(pasteboard);
	pasteboard['fileHandler'] = new fileHandler(pasteboard);
	pasteboard['imageEditor'] = new imageEditor(pasteboard);
	pasteboard['appFlow'] = new appFlow(pasteboard);
    });
})(jQuery);
