jQuery.noConflict();

jQuery(document).ready(function ($) {
    var PLAN_CASE_MENU = {
	contextmenu: {
	    remove: {
		label: IMPASSE.label.buttonDelete,
		icon:  IMPASSE.url.iconDelete,
		action: function(node) { this.remove(node); }
	    }
	}
    };

    $("#testplan-tree")
	.bind("before.jstree", function (e, data) {
	})
	.bind("loaded.jstree", function (e, data) {
	    $(this).find("li[rel=test_case]").data("jstree", PLAN_CASE_MENU);
	    $(this).find("li[rel!=test_case]").data("jstree", {contextmenu:{}});
	})
	.bind("remove.jstree", function (e, data) {
	    data.rslt.obj.each(function () {
		$.ajax({
		    type: 'POST',
		    url: IMPASSE.url.testPlansRemove,
		    data : {
			format: "json",
			test_plan_id: test_plan_id,
			test_case_id: this.id.replace("plan_","")
		    }, 
		    success : function (r) {
			if(!r.status) {
			    data.inst.refresh();
			}
		    },
		    error: function(xhr, status, ex) {
			ajax_error_handle(xhr, status, ex);
			$.jstree.rollback(data.rlbk);
		    }
		});
	    });
	})
	.jstree({ 
	    "plugins" : [ 
		"themes","json_data","ui","crrm","cookies","dnd","search","types","hotkeys", "contextmenu"
	    ],
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
			var p = this._get_parent(m.o);
			if(!p) return false;
			p = p == -1 ? this.get_container() : p;
			if(p === m.np) return true;
			if(p[0] && m.np[0] && p[0] === m.np[0]) return true;
			return false;
			return true;
		    }
		}
	    },
	    dnd: {
		drag_finish: function(data) {
		    var $this = this;
		    var draggable = $(data.o).hasClass("jstree-draggable") ? $(data.o) : $(data.o).parents(".jstree-draggable");
		    var request = {
			format: "json",
			"test_plan_case[test_plan_id]": test_plan_id,
			"test_plan_case[test_case_id]": data.r.attr("id").replace("plan_", "")
		    };
		    if (draggable.hasClass("test-day")) {
			var date = $("#calendar-view").datepicker("getDate");
			date.setDate($(data.o).text());
			request["execution[expected_date]"] = date.toUTCString();
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
			    ajax_error_handle(xhr, status, ex);
			}
		    });
		}
	    }
	});
    var cal = $("#calendar-view").datepicker();
    $(".ui-datepicker-calendar td:not(.ui-datepicker-other-month)", cal)
	.addClass("jstree-draggable").addClass("test-day");
});
