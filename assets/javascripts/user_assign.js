jQuery.noConflict();

jQuery(document).ready(function ($) {
    var USER_ASSIGN_MENU = {
	remove: {
	    label: IMPASSE.label.buttonDelete,
	    icon:  IMPASSE.url.iconDelete,
	    action: function(node) {
		var $this = this;
                $.ajax({
                    type: 'POST',
                    url: IMPASSE.url.executionsDelete,
                    data: {
			"test_plan_case[test_plan_id]": test_plan_id,
			"test_plan_case[test_case_id]": node.attr("id").replace("plan_", "")
		    },
                    success: function(r) {
                        $this.refresh($this._get_parent(node));
                    },
                    error: function(xhr, status, ex) {
                        ajax_error_handler(xhr, status, ex);
                    }
                });
		
	    }
	}
    };

    var plugins = ["themes","json_data","ui","cookies","types","hotkeys"];
    if (IMPASSE.canEdit) {
	plugins = plugins.concat(["dnd", "crrm", "contextmenu"]);
    }
    $("#testplan-tree")
	.bind("remove.jstree", function (e, data) {
	    data.rslt.obj.each(function () {
		$.ajax({
		    type: 'POST',
		    url: IMPASSE.url.testPlansRemove,
		    data : {
			test_plan_id: test_plan_id,
			test_case_id: this.id.replace("plan_","")
		    }, 
		    success : function (r) {
			if(!r.status) {
			    data.inst.refresh();
			}
		    },
		    error: function(xhr, status, ex) {
			ajax_error_handler(xhr, status, ex);
			$.jstree.rollback(data.rlbk);
		    }
		});
	    });
	})
	.jstree({ 
	    "plugins" : plugins,
	    core : {
		animation: 0
	    },
	    json_data: { 
		ajax: {
		    url: IMPASSE.url.executionsList,
		    data: function (n) { 
			return { 
			    prefix: "plan",
			    id: n.attr ? n.attr("id").replace("plan_","") : -1
			}; 
		    },
		    progressive_render: true
		}
	    },
	    contextmenu: {
		items: function (n) {
		    if (n.attr("rel") == 'test_suite' || n.attr("rel") == 'test_case')
			return USER_ASSIGN_MENU;
		}
	    },
	    types: {
		max_depth: -2,
		max_children: -2,
		valid_children: [ "test_project" ],
		types: {
		    test_case: {
			valid_children: "none",
			icon: { image: IMPASSE.url.iconTestCase }
		    },
		    test_suite: {
			valid_children: [ "test_suite", "test_case" ],
			icon: { image: IMPASSE.url.iconTestSuite }
		    },
		    test_project: {
			valid_children: [ "test_suite", "test_case" ],
			icon: { image: IMPASSE.url.iconProject },
			start_drag: false,
			move_node: false,
			delete_node: false,
			remove: false
		    }
		}
	    },
	    crrm: {
		move: {
		    check_move: function (m) { 
			return false;
		    }
		}
	    },
	    dnd: {
		drag_finish: function(data) {
		    var $this = this;
		    var draggable = $(data.o).hasClass("jstree-draggable") ? $(data.o) : $(data.o).parents(".jstree-draggable");
		    var request = {
			"test_plan_case[test_plan_id]": test_plan_id,
			"test_plan_case[test_case_id]": data.r.attr("id").replace("plan_", "")
		    };
		    if (draggable.hasClass("test-day")) {
			var date = $("#calendar-view").datepicker("getDate");
			date.setDate($(data.o).text());
			request["execution[expected_date]"] = date.getTime() / 1000;
		    } else if (draggable.hasClass("test-member")) {
			request["execution[tester_id]"] = data.o.id.replace("principal-", "");
		    }

		    $.ajax({
			type: 'POST',
			url: IMPASSE.url.executionsPut,
			data: request,
			success: function(r) {
			    $this.refresh($this._get_parent(data.r));
			},
			error: function(xhr, status, ex) {
			    ajax_error_handler(xhr, status, ex);
			}
		    });
		}
	    }
	});

    var orig_updateDatepicker = jQuery.datepicker._updateDatepicker;
    jQuery.datepicker._updateDatepicker = function(inst) {
	orig_updateDatepicker.apply(this, [inst]);
	$(".ui-datepicker-calendar td:not(.ui-datepicker-other-month)", inst.dpDiv)
	    .addClass("jstree-draggable").addClass("test-day");
    };

    $("#calendar-view").datepicker({
	onChangeMonthYear: function(year, month, inst) {
	    $(this).datepicker("setDate", new Date(year, month-1, 1));
	}
    });

    $("#cal-user-view").floatmenu();
});

