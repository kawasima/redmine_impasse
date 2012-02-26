function impasse_loading_options() {
    return {
	message: '<span>loading...</span>',
	css: {
	    backgroundPosition: "0% 40%",
	    backgroundRepeat: "no-repeat",
	    backgroundImage: "url(../images/loading.gif)",
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
    if(xhr.status == 401) {
	message = "Unauthorized!";
    }
    show_notification_dialog('error', message);
}

function show_notification_dialog(type, message) {
    STYLE = {
	success: {
	    background: "-webkit-gradient(linear, 0% 0%, 0% 100%, from(rgb(240, 255, 200)), to(rgb(180, 255, 180)))",
	    color: "#2f7c00",
	    borderBottom: "1px solid #2f7c00"
	},
	error: {
	    background: "-webkit-gradient(linear, 0% 0%, 0% 100%, from(rgb(255, 240, 240)), to(rgb(255, 180, 180)))",
	    color: "#a20510",
	    borderBottom: "1px solid #a20510"
	}
    };
    var dialog = jQuery("div#message-dialog");
    if(dialog.size() == 0) {
	dialog = jQuery('<div id="message-dialog"></div>').appendTo(jQuery("body"));
	dialog.dialog({
	    autoOpen: false,
	    position: [0, 0],
	    width: "105%",
	    height: 51,
	    draggable: false,
	    resizable: false,
	    show: "blind",
	    hide: "blind"
	});
    }
    dialog.empty().append(jQuery("<p/>").css({textAlign:'center'}).text(message))
    dialog.siblings(".ui-dialog-titlebar:first").hide();
    dialog.parents(".ui-widget-content").css({background:"transparent", border: "none"});
    dialog.css(jQuery.extend({ padding: 0, font:"bold 14px arial", overflow: 'hidden', textShadow: '0 1px 0 #fff'}, STYLE[type]));
    dialog.dialog('open');
    setTimeout(function() {dialog.dialog('close'); }, 2500);
}
