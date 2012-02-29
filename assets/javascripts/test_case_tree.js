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
			position: $("#testcase-tree").jstree("get_index", node),
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
		action: function(node) { this.remove(node); }
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

    var dialog = {
	test_suite: $("#testsuite-dialog").dialog({
	    autoOpen: false,
	    modal:true,
	    minWidth: 700,
	    title: IMPASSE.label.testSuiteEdit
	}),
	test_case:  $("#testcase-dialog").dialog({
	    autoOpen: false,
	    modal:true,
	    minWidth: 700,
	    title: IMPASSE.label.testCaseEdit
	})
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
		dialog[node_type].empty().append(html);
		dialog[node_type].find(".ui-button-cancel").click(function(e) {
		    dialog[node_type].dialog('close');
		});
		dialog[node_type].dialog('open');
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

		dialog[node_type].find(":button.ui-button-submit").click(function(e) {
		    var tc = {format:"json"};
		    dialog[node_type].find(":hidden,:text,textarea,:checkbox:checked,radiobutton:checked,select").each(function() {
			tc[$(this).attr("name")] = $(this).val();
			
		    });
		    if (edit_type == 'edit')
			tc["node[id]"] = node.attr("id").replace("node_","");
		    tc["node_type"] = node_type;
		    tc["node[parent_id]"] = $(data.rslt.parent).attr("id").replace("node_", "");
		    tc["node[node_order]"] = data.rslt.position;
		    $.ajax({
			type: 'POST',
			url:AJAX_URL[edit_type],
			data: tc,
			success: function(r, status, xhr) {
			    if (!r || r.length == 0) {
				ajax_error_handler(xhr, status, "data not found.");
				
			    }
			    $.each(r, function(i, n) {
				dialog[node_type].unbind("dialogbeforeclose");
				node.attr("id", "node_" + n.id);
				node.data("jstree", (node_type=='test_case')?LEAF_MENU:FOLDER_MENU);
				$.jstree._reference(node).set_text(node, tc["node[name]"]);
				show_notification_dialog(
				    'success',
				    edit_type=='edit' ? IMPASSE.label.noticeSuccessfulUpdate : IMPASSE.label.noticeSuccessfulCreate);
			    });
			},
			error: ajax_error_handler,
			complete: function() { dialog[node_type].dialog('close'); }
		    });
		});
	    },
	    error: ajax_error_handler
	});
    };

    var testcaseTree =$("#testcase-tree")
	.jstree({ 
	    "plugins": [
		"themes","json_data","ui","crrm","cookies","dnd","search","types","hotkeys","contextmenu" 
	    ],
	    core: {
		animation: 0
	    },
	    contextmenu: {
		select_node: true
	    },
	    json_data: { 
		ajax: {
		    url: IMPASSE.url.testCaseList,
		    data: function (n) { 
			return { 
			    prefix: "node", 
			    node_id: n.attr ? n.attr("id").replace("node_","") : -1
			}; 
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
	    }
	})
	.bind("loaded.jstree", function (e, data) {
	    $(this).find("li[rel=test_project],li[rel=test_suite]").data("jstree", FOLDER_MENU);
	    $(this).find("li[rel=test_case]").data("jstree", LEAF_MENU);
	})
	.bind("refresh.jstree", function (e, data) {
	    $(this).find("li[rel=test_project],li[rel=test_suite]").data("jstree", FOLDER_MENU);
	    $(this).find("li[rel=test_case]").data("jstree", LEAF_MENU);
	})
	.bind("create.jstree", function (e, data) {
	    dialog[$(data.rslt.obj).attr("rel")].bind('dialogbeforeclose', function(e) {
		$.jstree.rollback(data.rlbk);
	    });
	    openDialog(data, 'new');
	})
	.bind("remove.jstree", function (e, data) {
	    var request = {format: "json", "node[id]": []};
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
	    var request = { format: "json" };
	    data.rslt.o.each(function (i, node) {
		request["nodes["+i+"][id]"]         = $(node).attr("id").replace("node_","");
		request["nodes["+i+"][parent_id]"]  = data.rslt.cr === -1 ? 1 : data.rslt.np.attr("id").replace("node_",""), 
		request["nodes["+i+"][node_order]"] = data.rslt.cp + i
	    });
	    if (data.rslt.cy) {
		data.rslt.oc.each(function(i, node) {
		    request["nodes["+i+"][original_id]"] = $(node).attr("id").replace("copy_node_","")
		});
	    }
	    var dest = $(data.rslt.oc);
	    $("ins.jstree-icon", dest).css({backgroundImage: "url(" + IMPASSE.url.loading + ")"});
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
	});

    $("#testcase-dialog .add-test-step").live("click", function() {
	var id = 0;
	var test_steps = $("#testcase-dialog table.list");
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
});
