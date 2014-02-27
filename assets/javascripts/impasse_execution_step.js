

$(document).ready(function () {
 
$('.status_step_execucao').die('change').live('change',function(){
	var $this = $(this);
	var post_save_function = function() { jQuery.unblockUI(); };
	
	var execution_status = $('#edit_execution').find(":radio[name='execution[status]']:checked").val();

	if($(this).val() == 'Com falha') { // NG

	    post_save_function = function() {
		$.get(IMPASSE.url.executionBugsNewStep, {},
			function(data) {
			    jQuery.unblockUI();
			    $("#issue-dialog").html(data).dialog({
				modal:true,
				minWidth: 900,
				zIndex: 25,
				title: IMPASSE.label.issueNew
			    });
			});
	    };
	}
	$.ajax({
	    url: IMPASSE.url.executionsPut,
	    type: 'POST',
	    data: $('#edit_execution').serialize() + "&record=true",
	    success: function(data) {
		show_notification_dialog(data.status, data.message);
		if (data.errors) {
		    var ul = $("<ul/>");
		    $.each(data.errors, function(i, error) {
			ul.append($("<li/>").html(error));
		    });
		    $("#errorExplanation")
			.html(ul)
			.show();
		} else {
		    $("#errorExplanation").hide();
		    post_save_function();
		    var test_case_id = $(":hidden[name='test_plan_case[test_case_id]']" ,$this).val();
		    $("#testplan-tree li#exec_"+test_case_id+" a  ins").css({backgroundImage: "url("+EXEC_ICONS[execution_status]+")"});
		}
	    },
	    complete: function(data) {
		jQuery.unblockUI();
		$("#issue-dialog").dialog("close");
	    }
	});
	jQuery.blockUI({ message: "<h1>Saving...</h1>"});
	return false;
	
}); 	

 
 
// alert("document change");
 
 //var form = jQuery('#edit_execution');
 //alert(form.attr('action'));
	 //jQuery('.status_step_execucao').change(function(e){
	 	
	//var $this = $(this);
	//var post_save_function = function() { $.unblockUI() };
	
	//	alert("val = "+jQuery(this).val());
	 //	alert("attr = "+jQuery(this).attr('codigo'));
	// if(jQuery(this).val() == jQuery(this).val()) { // NG
	 //    post_save_function = function() {
	  //   	alert(IMPASSE.url.executionBugsNewStep);
	//	 $.get(IMPASSE.url.executionBugsNewStep, {},
			// function(data) {
			// 	alert("get");
			 //    $.unblockUI();
			 //    $("#issue-dialog").html(data).dialog({
			//	 modal:true,
			//	 minWidth: 900,
			//	 zIndex: 25,
			//	 title: IMPASSE.label.issueNew
			 //    });
		//	 });
	     //};
	 //}
	//
	 	
	 //alert('.ALTERADO change');
	 	 	//alert(jQuery('.status_step_execucao').change);
	 	 	
	  	//alert(jQuery(this).val());
	 	//alert(jQuery(this).attr('codigo'));
	 	
	//var form = jQuery('#edit_execution');
	
	//form.attr('action','micahel');
	//console.log(form.attr('action'));
	//form.submit();
	
	//});
  
});
