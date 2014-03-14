$(document).ready(function() {

	$('.status_step_execucao').die('change').live('change', function() {
		var $this = $(this);
		var post_save_function = function() {
			jQuery.unblockUI();
		};

		var execution_status = $('#edit_execution').find(":radio[name='execution[status]']:checked").val();

   //     alert(" issue_test_steps_id => "+$this.attr('test_step_id'));
   //     alert(" issue_test_step_status => "+$this.val());
   //     alert(" issue_test_case_id => "+$this.attr('test_case_id'));
   //     alert(" issue_test_plan_id => "+$this.attr('test_plan_id'));
                           
		if ($this.val() == 'Com falha') {// NG
			//post_save_function = function() {
			$.get(IMPASSE.url.executionBugsNewStep, {}, function(data) {
				jQuery.unblockUI();
				$("#issue-dialog-step").html(data).dialog({
					modal : true,
					minWidth : 900,
					zIndex : 25,
					title : IMPASSE.label.issueNew + ' Adicionando falha do passo test_step_id = ' + $this.attr('test_step_id') + " situacao = " + $this.val()
				});
				
		$("#issue_test_steps_id").val($this.attr('test_step_id'));
        $("#issue_test_step_status").val($this.val());
        $("#issue_test_case_id").val($this.attr('test_case_id'));
        $("#issue_test_plan_id").val($this.attr('test_plan_id'));
			});
			//};
		}else {
			$.ajax({
				url : IMPASSE.url.executionsStepPut,
				type : 'POST',
				data : $('#edit_execution').serialize()+ "&test_step_id=" + $this.attr('test_step_id')+"&test_step_status="+ $this.val()+"&test_case_id="+$this.attr('test_case_id')+"&test_plan_id="+$this.attr('test_plan_id'),
				success : function(data) {
					show_notification_dialog(data.status, data.message);
					if (data.errors) {
						var ul = $("<ul/>");
						$.each(data.errors, function(i, error) {
							ul.append($("<li/>").html(error));
						});
						$("#errorExplanation").html(ul).show();
					} else {
						$("#errorExplanation").hide();
						post_save_function();
						var test_case_id = $(":hidden[name='test_plan_case[test_case_id]']", $this).val();
		
	
						$("#testplan-tree li#exec_" + test_case_id + " a  ins").css({
							backgroundImage : "url(" + EXEC_ICONS[execution_status] + ")"
						});
					}
	
				},
				complete : function(data) {
					jQuery.unblockUI();
					//$("#issue-dialog").dialog("close");
				}
			});
			jQuery.blockUI({
				message : "<h1>Salvando situação do passo</h1>"
			});
		}
		
		return false;
	});

	$("#issue-dialog-step #button-create-issue-step").die('click').live("click", function(e) {
		alert("estou aqui #issue-dialog-step #button-create-issue-step");
		$.ajax({
			url : IMPASSE.url.executionBugsNewStepCreate,
			type : 'POST',
			data : $("#issue-form").serialize() + "&execution_bug_step[test_step_id]=" + $("#executions-view :hidden#execution_id").val(),
			success : function(data) {
				if (data.errors) {
					if ($("#issue-dialog-step .errorExplanation").size() == 0)
						$("#issue-dialog-step").prepend($("<div/>").addClass("errorExplanation").attr("id", "errorExplanation"));
					var list = $("<ul/>");
					$.each(data.errors, function(i, msg) {
						list.append($("<li/>").text(msg));
					});
					$("#issue-dialog-step #errorExplanation").html(list);
					return;
				} else {
					$("#issue-dialog-step form#attachments-form :hidden[name=issue_id]").val(data.issue_id);
					$("#issue-dialog-step form#attachments-form").submit();
				}
				var bugs = $("#execution-bugs-list");

				if (bugs)
					bugs.append(",");
				bugs.append($("<a/>").attr("href", IMPASSE.url.issue + "/" + data['issue_id']).text("#" + data['issue_id'])).parents("p:first").show();
				$("#issue-dialog-step").dialog("close");
			},
			complete : function(data) {
					jQuery.unblockUI();
					//$("#issue-dialog").dialog("close");
				}
		});
		//$("#issue-dialog").block({message : "<h1>Salvando passo</h1>"});
		jQuery.blockUI({
				message : "<h1>Salvando situação do passo</h1>"
			});
		return false;
	});

});
