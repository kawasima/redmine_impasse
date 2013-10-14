jQuery.noConflict();
jQuery(document).ready(function ($) {
    var AJAX_URL = {
	"new":  IMPASSE.url.testCaseNew,
	"edit": IMPASSE.url.testCaseEdit
    };
    var LEAF_MENU = {
	contextmenu: {
	    edit: {
		label: IMPASSE.label.buttonEdit,
		icon:  IMPASSE.url.iconEdit,
		action: function(node) { openDialog({
		    rslt: {
			name: $("#testcase-tree").jstree("get_text", node),
			obj: node,
			parent: $(node).parents("li:first")
		    }
		}, 'edit'); }
	    },
	    copy: {
		label: IMPASSE.label.buttonCopy,
		icon:  IMPASSE.url.iconCopy,
		action: function(node) { this.copy(node); }
	    },
	    remove: {
		label: IMPASSE.label.buttonDelete,
		icon:  IMPASSE.url.iconDelete,
		action: function(node) {
		    if (confirm(IMPASSE.label.textAreYouSure)) {
			this.remove(node);
		    }
		}
	    }
	}
    };
    var FOLDER_MENU = {
	contextmenu: {
	    create: {
		label: IMPASSE.label.buttonCreate,
		icon:  IMPASSE.url.iconAdd,
		submenu: {
		    createTestSuite: {
			label: "Test suite",
			icon: IMPASSE.url.iconTestSuite,
			action: function(node) {
			    this.create(node, "last", {attr: {rel: "test_suite"}}, null, true);
			}
		    },
		    createTestCase: {
			label: "Test case",
			icon: IMPASSE.url.iconTestCase,
			action: function(node) {
			    this.create(node, "last", {attr: {rel: "test_case"}}, null, true);
			}
		    }
		}
	    },
	    edit: LEAF_MENU.contextmenu.edit,
	    copy: LEAF_MENU.contextmenu.copy,
	    paste: {
		label: "Paste",
		action: function(node) { this.paste(node); }
	    },
	    remove: LEAF_MENU.contextmenu.remove
	}
    };
    var ROOT_MENU = {
	contextmenu: {
	    create: FOLDER_MENU.contextmenu.create,
	    paste:  FOLDER_MENU.contextmenu.paste
	}
    };

    var dialog = {
	test_suite: $("#testsuite-dialog").dialog({
	    autoOpen: false,
	    modal:true,
	    minWidth: 700,
	    zIndex: 25,
	    title: IMPASSE.label.testSuiteEdit
	}),
	test_case:  $("#testcase-dialog").dialog({
	    autoOpen: false,
	    modal:true,
	    minWidth: 700,
	    zIndex: 25,
	    title: IMPASSE.label.testCaseEdit
	})
    };
    function show_test_case(node_id) {
	$.ajax({
	    url: IMPASSE.url.testCaseShow,
	    data: { "node[id]": node_id },
		success: function(html) {
			var winHeight = $(window).height();
			var $testCaseView = $("#test-case-view");
			$testCaseView.css({height:'', overflow:''}).html(html).show();
			$(".screenshots", $testCaseView).tinycarousel();
			if ($testCaseView.height() > winHeight) {
				$testCaseView.height(winHeight - 1).css('overflow', 'scroll');
			}
		},
	    error: ajax_error_handler,
	    complete: function() {
		$("#test-case-view").unblock();
	    }
	});
    }

    function split( val ) {
	return val.split( /,\s*/ );
    }
    function extractLast( term ) {
	return split( term ).pop();
    }

    function setupKeyword(completeBox, availableTags) {
	completeBox.autocomplete({
	    minLength: 0,
	    source: function( request, response ) {
		response( $.ui.autocomplete.filter(
		    availableTags, extractLast( request.term ) ) );
	    },
	    focus: function() {
		// prevent value inserted on focus
		return false;
	    },
	    select: function( event, ui ) {
		var terms = split( this.value );
		// remove the current input
		terms.pop();
		// add the selected item
		terms.push( ui.item.value );
		// add placeholder to get the comma-and-space at the end
		terms.push( "" );
		this.value = terms.join( ", " );
		return false;
	    }
	});
    }
    var updateTestCase = function(data, edit_type) {
	var node = $(data.rslt.obj);
	var node_type = node.attr("rel");
	return function(e) {
	var ajaxOptions = {
	    type: 'POST',
	    url:AJAX_URL[edit_type],
	    success: function(r, status, xhr) {
		if (r.errors) {
		    var ul = $("<ul/>");
		    $.each(r.errors, function(i, error) {
			ul.append($("<li/>").html(error));
		    });
		    $("#errorExplanation", dialog[node_type])
			.html(ul)
			.show();
		    var top = $("#errorExplanation", dialog[node_type]).position().top;
		    $(window).scrollTop(top);
		    return;
		}
		$.each(r.ids, function(i, id) {
		    dialog[node_type].unbind("dialogbeforeclose");
		    node.attr("id", "node_" + id);
		    node.data("jstree", (node_type=='test_case')?LEAF_MENU:FOLDER_MENU);
		    $.jstree._reference(node).set_text(node, tc["node[name]"]);
		});
		dialog[node_type].dialog('close');
		show_notification_dialog(r.status, r.message);
	    },
	    error: ajax_error_handler,
	    complete: function() {
		dialog[node_type].find(":button.ui-button-submit").one("click", updateTestCase(data, edit_type));
	    }
	};
	var tc = {};
	dialog[node_type].find(":input:hidden,:text,textarea,:checkbox:checked,radiobutton:checked,select").each(function() {
	    tc[$(this).attr("name")] =  $(this).val();
	});
	if (edit_type == 'edit')
	    tc["node[id]"] = node.attr("id").replace("node_","");
	tc["node_type"] = node_type;
	tc["node[parent_id]"] = $(data.rslt.parent).attr("id").replace("node_", "");
	tc["node[node_order]"] = data.rslt.obj.parent().children().index(data.rslt.obj);
	if (window.FormData) {
	    var formData = new FormData();
	    $(".new-screenshot", dialog[node_type]).each(function(i) {
		formData.append("attachments["+i+"][file]", dataURLtoBlob(this.src) ,'screenshot.png');
	    });
	    for (var key in tc) { formData.append(key, tc[key]) }
	    
	    ajaxOptions["data"] = formData;
	    ajaxOptions["contentType"] = false;
	    ajaxOptions["processData"] = false;
	} else {
	    ajaxOptions["data"] = tc;
	}
	$.ajax(ajaxOptions);
	}
    };

    var openDialog = function(data, edit_type) {
	var node = $(data.rslt.obj);
	var node_type = node.attr("rel");
	var request = { node_type: node_type };
	if (node.attr("id")) {
	    request['node[id]'] = node.attr("id").replace("node_", "");
	}

	$.ajax({
	    url: AJAX_URL[edit_type],
	    data: request,
	    success: function(html) {
		dialog[node_type].html(html);
		dialog[node_type].find(".ui-button-cancel").click(function(e) {
		    dialog[node_type].dialog('close');
		});
		dialog[node_type].dialog('open');
		$.getJSON(IMPASSE.url.testKeywords, function(json) { setupKeyword($("input[name=node_keywords]", dialog[node_type]), json) });
		dialog[node_type].find(".sortable").sortable({
		    handle: ".ui-sort-handle",
		    placeholder: 'ui-state-highlight',
		    update: function(e, ui) {
			var i=1;
			$(this).find("tr").each(function() {
			    var row = $(this);
			    $("td.ui-sort-handle", row).text(i);
			    $("input[name*=step_number]", row).each(function() {
				$(this).val(i);
			    });
			    $("textarea,:hidden", row).each(function() {
				var f = $(this);
				f.attr("name", f.attr("name").replace(/\[\d+\]/, "["+i+"]"));
			    });
			    i++;
			});
		    }
		});
		$(".sortable .icon-del", dialog[node_type]).click(function(e) {
		    $(this).parents("tr:last").remove();
		});

		$(".screenshots", dialog[node_type]).tinycarousel();

		dialog[node_type].find(":button.ui-button-submit").one("click", updateTestCase(data, edit_type));
	    },
	    error: ajax_error_handler
	});
    };

    var plugins = ["themes","json_data","ui","cookies","types", "hotkey"];
    if (IMPASSE.canEdit) {
	plugins = plugins.concat(["crrm","dnd","contextmenu", "checkbox"]);
    }

    var prepared_checkbox = false;
    var testcaseTree =$("#testcase-tree")
	.jstree({ 
	    plugins: plugins,
	    core: {
		animation: 0
	    },
	    contextmenu: {
		select_node: true,
		items: function(node) {
		    if (node.attr('rel') == 'test_project')
			return ROOT_MENU.contextmenu;
		    else if (node.attr('rel') == 'test_suite')
			return FOLDER_MENU.contextmenu;
		    else if (node.attr('rel') == 'test_case')
			return LEAF_MENU.contextmenu;
		}
	    },
	    json_data: { 
		ajax: {
		    url: IMPASSE.url.testCaseList,
		    data: function (n) {
			var data = {
			    prefix: "node", 
			    node_id: n.attr ? n.attr("id").replace("node_","") : -1
			};
			$("#filters").find(":text[name],:checkbox:checked").each(function() {
			    var el = $(this);
			    if (el.val())
				data[el.attr("name")] = el.val();
			});
			return data;
		    }
		}
	    },
	    types: {
		max_depth: -2,
		max_children: -2,
		valid_children: [ "test_project" ],
		types: {
		    test_case: {
			valid_children: "none",
			icon: {
			    image: IMPASSE.url.iconTestCase
			}
		    },
		    test_suite: {
			valid_children: [ "test_suite", "test_case" ],
			icon: {
			    image: IMPASSE.url.iconTestSuite
			}
		    },
		    test_project: {
			valid_children: [ "test_suite", "test_case" ],
			icon: {
			    image: IMPASSE.url.iconProject
			},
			start_drag: false,
			move_node: false,
			delete_node: false,
			remove: false
		    }
		}
	    },
	    dnd: {
		drag_finish: function(data) {
		    var $this = this;
		    var draggable = $(data.o).hasClass("jstree-draggable") ? $(data.o) : $(data.o).parents(".jstree-draggable");
		    var request = {
			"issue_id": draggable.attr("id").replace("issue-", ""),
			"test_case_id": data.r.attr("id").replace("node_", "")
		    };
		    $.ajax({
			type: 'POST',
			url: IMPASSE.url.requirementIssuesAddTestCase,
			data: request,
			success: function(r) {
			    show_notification_dialog(r.status, r.message);
			},
			error: function(xhr, status, ex) {
			    ajax_error_handler(xhr, status, ex);
			}
		    });
		}
	    },
	    checkbox: {
		two_state: false
	    }
	})
	.bind("loaded.jstree refresh.jstree", function (e, data) {
	    if (!prepared_checkbox) {
		testcaseTree.jstree('hide_checkboxes');
		prepared_checkbox = true;
	    }
	})
	.bind("create.jstree", function (e, data) {
	    dialog[$(data.rslt.obj).attr("rel")].bind('dialogbeforeclose', function(e) {
		$.jstree.rollback(data.rlbk);
	    });
	    openDialog(data, 'new');
	})
	.bind("remove.jstree", function (e, data) {
	    var request = {"node[id]": []};
	    data.rslt.obj.each(function() {
		request["node[id]"].push(this.id.replace("node_", ""));
	    });
	    $.ajax({
		async: false,
		type: 'POST',
		url: IMPASSE.url.testCaseDestroy,
		data: request,
		success: function (r) {
		    if(!r.status) {
			$.jstree.rollback(data.rlbk);
		    }
		    data.inst.refresh(data.rslt.parent);
		},
		error: function(xhr, status, ex) {
		    ajax_error_handler(xhr, status, ex);
		    $.jstree.rollback(data.rlbk);
		}
	    });
	})
	.bind("copy.jstree", function(e, data) {
	})
	.bind("move_node.jstree", function (e, data) {
	    var url = (data.rslt.cy) ? IMPASSE.url.testCaseCopy : IMPASSE.url.testCaseMove;
	    var request = {};
	    data.rslt.o.each(function (i, node) {
		request["nodes["+i+"][id]"]         = $(node).attr("id").replace("node_","");
		request["nodes["+i+"][parent_id]"]  = data.rslt.cr === -1 ? 1 : data.rslt.np.attr("id").replace("node_","");
		request["nodes["+i+"][node_order]"] = data.rslt.cp + i;
	    });
	    if (data.rslt.cy) {
		data.rslt.oc.each(function(i, node) {
		    request["nodes["+i+"][original_id]"] = $(node).attr("id").replace("copy_node_","");
		});
	    }
	    var dest = $(data.rslt.oc);
	    $("ins.jstree-icon", dest).css({backgroundImage: "url(" + IMPASSE.url.iconLoading + ")"});
	    $.ajax({
		type: 'POST',
		url: url,
		data: request,
		success : function (r) {
		    if(!r || r.length == 0) {
			$.jstree.rollback(data.rlbk);
		    }
		    else {
			dest.each(function(i) {
			    var node = $(this);
			    node.attr("id", "node_" + r[i].id);
			    data.inst.set_text(node, r[i].name);
			    node.data("jstree", (dest.attr("rel")=="test_case") ? LEAF_MENU : FOLDER_MENU);
			    if(data.rslt.cy && dest.children("UL").length) {
				data.inst.refresh(data.inst._get_parent(data.rslt.oc));
			    }
			});
			$("ins.jstree-icon", dest).css("backgroundImage", "");
		    }
		},
		error: function(xhr, status, ex) {
		    $.jstree.rollback(data.rlbk);
		    ajax_error_handler(xhr, status, ex);
		}
	    });
	})
	.bind("select_node.jstree", function(e, data) {
	    $("#test-case-view").block(impasse_loading_options());
	    var node_id = data.rslt.obj.attr("id").replace("node_", "");
	    location.replace("#testcase-" + node_id);
	    show_test_case(node_id);
	});

    $("#testcase-dialog .add-test-step").live("click", function() {
	var id = 0;
	var test_steps = $("#testcase-dialog table.test-steps");
	test_steps.find("td.ui-sort-handle").each(function() {
	    if (id < Number($(this).text()))
		id = Number($(this).text());
	});
	id += 1;

	var actions = $("<textarea/>").attr("name", "test_steps["+id+"][actions]")
	    .attr("rows", 3).css({width:"100%", padding:0, margin:0});
	var expected_results = $("<textarea/>").attr("name", "test_steps["+id+"][expected_results]")
	    .attr("rows", 3).css({width:"100%", padding:0, margin:0});
	var step_number = $("<input/>").attr("type", "hidden")
	    .attr("name", "test_steps["+id+"][step_number]")
	    .attr("value", id);

	var del_button = $("<td/>");
	var test_step = $("<tr/>").addClass("entry")
	    .append($("<td/>").addClass("ui-sort-handle").text(id))
	    .append($("<td/>").append(actions).append(step_number))
	    .append($("<td/>").append(expected_results))
	    .append(del_button);
	del_button.append($("<span class='icon icon-del'/>").click(function(e) {
	    test_step.remove();
	}));
	test_steps.append(test_step);

	return false;
    });

    $(".splitcontentright .floating").floatmenu();

    $.getJSON(IMPASSE.url.testKeywords, function(json) {
	setupKeyword($(".filter :input#filters_keywords"), json);
    });

    if (location.hash && location.hash.lastIndexOf("#testcase-", 0) == 0) {
	var testcase_id = location.hash.replace(/^#testcase-/, "");
	show_test_case(testcase_id);
    }

    $("#button-requirement-issues").bind("click", function(e) {
	$.ajax({
	    url: IMPASSE.url.requirementIssues,
	    data: { },
	    success: function(html) {
					$("#requirements-view").html(html).show();
					$("a.page,a.next, span.per-page a").live("click", function(e) {
			           var oldurl = $(this).attr("href");
				       $("a.page").attr("href","#");
					   $("a.next").attr("href","#");
					   $("span.per-page a").attr("href","#");
				       $.ajax({
					     url: oldurl,
					     data: { },
					     success: function(html) {
					        $("#requirements-view").html(html).show();
					        },
					        error: ajax_error_handler
				        });
				    });	
	    },
	    error: ajax_error_handler
	});
    });

    $("#button-requirement-issues").bind("click", function(e) {
	$.ajax({
	    url: IMPASSE.url.requirementIssues,
	    data: { },
	    success: function(html) {
					$("#requirements-view").html(html).show();
					$("a.page").live("click", function(e) {
			           var oldurl = $(this).attr("href");
				       $("a.page").attr("href","#");
				       $.ajax({
					     url: oldurl,
					     data: { },
					     success: function(html) {
					        $("#requirements-view").html(html).show();
					        },
					        error: ajax_error_handler
				        });
				    });	
	    },
	    error: ajax_error_handler
	});
    });

    $("#button-close-requirements").live("click", function(e) {
	$("#requirements-view").hide();
	e.preventDefault();
    });

    $("#values_fixed_version_id").live("change", function(e) {
	var version_id = $(this).val();
	$.ajax({
	    url: IMPASSE.url.requirementIssues,
	    data: { "fields": ['fixed_version_id'], "values[fixed_version_id]": [version_id], "operators[fixed_version_id]": version_id ? "=" : "!*"},
	    success: function(html) {
		$("#requirements-view").html(html).show();
	    },
	    error: ajax_error_handler
	});
    });

    $("#testcase-dialog a.remove_requirement").live("click", function(e) {
	var row = $(this).parents("tr");
	var requirementIssues = $(this).parents("div.requirement-issues");
	$.ajax({
	    type: 'post',
	    url: $(this).attr("href"),
	    success: function(html) {
		row.remove();
		if (requirementIssues.find("table tr").size() <= 1)
		    requirementIssues.remove();
	    },
	    error: ajax_error_handler
	});
	e.preventDefault();
    });

    $("#button-copy-cases").bind("click", function(e) {
	testcaseTree.jstree('show_checkboxes');
	$("#copy-tests-view").show();
    });
    $("#button-copy-exec").bind("click", function(e) {
	var form = $("#edit_copy_tests");
	testcaseTree.jstree('get_checked', null, false).each(function() {
	    $('<input type="hidden" name="node_ids[]"/>').val(this.id.replace(/^node_/, "")).appendTo(form);
	});
	form.submit();
    });
    $("#button-copy-cancel").bind("click", function(e) {
	testcaseTree.jstree('hide_checkboxes');
	$("#copy-tests-view").hide();
    });

    $("#testcase-dialog .add-screenshot").live("click", function(e) {
	if (!pasteboard.copyAndPaste.isSupported() || !pasteboard.dragAndDrop.isSupported()) {
	    alert("This browser doesn't support this feature.\nPlease use Firefox or Google chrome.");
	    return;
	}
	var screenshotOverlay = $('<div id="pasteboard"/>').appendTo("body");
	$('<div class="splash">Copy & Paste or Drag & Drop</div>')
	    .appendTo(screenshotOverlay);
	$('<button class="pasteboard-close" input type="button">Close</button>')
	    .appendTo(screenshotOverlay);
	pasteboard.overlay = screenshotOverlay;
	pasteboard.imageEditor.uploadImageCallback(function(image) {
	    image.width = 100; image.height = 100;
	    $(image).addClass("new-screenshot");
	    var anchor = $('<a href="#" class="screenshot-thumbnail"/>').append(image);
	    var screenshotDelete = $('<a href="#" class="screenshot-delete"/>')
		.append($('<img src="'+ IMPASSE.url.iconDelete +'"/>'));
	    $("#testcase-dialog .screenshots ul.overview").append($("<li/>").css({
		float: 'left', width: '100px', height: '100px'
	    }).append(anchor).append(screenshotDelete));
	    $("#testcase-dialog .screenshots").data("tcl").refresh();
	});
	pasteboard.appFlow.start();
    });

    $("#testcase-dialog .screenshot-delete").live("click", function(e) {
	if (!confirm(IMPASSE.label.textAreYouSure))
	    return false;
	var $this = $(this);
	if ($this.siblings("a:first").children("img").hasClass("new-screenshot")) {
	    $this.parents("li").remove();
	    $("#testcase-dialog .screenshots").data("tcl").refresh();
	} else {
	    $.ajax({
		type: 'post',
		url: IMPASSE.url.screenshotsDestroy,
		data: { attachment_id: $this.attr("id").replace(/^thumbnail-/, '') },
		success: function() {
		    $this.parents("li").remove();
		    $("#testcase-dialog .screenshots").data("tcl").refresh();
		}
	    });
	}
	return false;
    });
});

