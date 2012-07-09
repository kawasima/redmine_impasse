jQuery.noConflict();

jQuery(document).ready(function ($) {
    var PLAN_CASE_MENU = {
	contextmenu: {
	    remove: {
		label: IMPASSE.label.buttonDelete,
		icon:  IMPASSE.url.iconDelete,
		action: function(node) { this.remove(node) }
	    }
	}
    };

    $("#testcase-tree")
	.jstree({ 
	    "plugins": [ 
		"themes", "json_data","ui","crrm","cookies","dnd","search","types","hotkeys"
	    ],
	    json_data: { 
		ajax: {
		    url: IMPASSE.url.testCaseList,
		    data: function (n) { 
			return {
                            prefix: "tc",
			    node_id : n.attr ? n.attr("id").replace("tc_","") : -1
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
			},
			move_node: false,
			delete_node: false,
			remove: false
		    },
		    test_suite: {
			valid_children: [ "test_suite", "test_case" ],
			icon: {
			    image: IMPASSE.url.iconTestSuite
			},
			move_node: false,
			delete_node: false,
			remove: false
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
		drop_target: ".jstree-drop",
		drag_target: false,
		drop_finish: function(data) {
		    var $this = this;
		    $.post(
			IMPASSE.url.testPlansAdd,
			{ test_case_ids: $.map(data.o, function(n, i) { return $this._get_node(n).attr("id").replace("tc_", "") }),
			  test_plan_id: test_plan_id,
			  format: "json"
			},
			function(result) {
			    if(result.num) {
				$("#testplan-tree").jstree("refresh", -1);
			    }
			}
		    );
		}
	    }
	});

    $("#testplan-tree")
	.bind("before.jstree", function (e, data) {
	})
	.bind("loaded.jstree refresh.jstree", function (e, data) {
	    $("li[rel=test_case],li[rel=test_suite]", this).data("jstree", PLAN_CASE_MENU);
	    $("li[rel=test_project]", this).data("jstree", {contextmenu:{}});
	})
	.bind("contextmenu.jstree", function(e,data) {
	})
	.bind("remove.jstree", function (e, data) {
	    data.rslt.obj.each(function () {
		$.ajax({
		    async : false,
		    type: 'POST',
		    url: IMPASSE.url.testPlansRemove,
		    data : {
			format: "json",
			test_plan_id: test_plan_id,
			test_case_id: this.id.replace("plan_","")
		    }, 
		    success : function (r) {
			show_notification_dialog('success', IMPASSE.label.noticeSuccessfulDelete);
		    },
		    error: function(xhr, status, ex) {
			ajax_error_handler(xhr, status, ex);
			$.jstree.rollback(data.rlbk);
		    }
		});
	    });
	})
	.jstree({ 
	    "plugins" : [ 
		"themes", "json_data","ui","crrm","cookies","dnd","search","types","hotkeys", "contextmenu"
	    ],
	    json_data : { 
		ajax : {
		    url : IMPASSE.url.testPlanCaseList,
		    data : function (n) { 
			return { 
			    prefix: "plan",
			    "filters[inactive]": true,
			    node_id : n.attr ? n.attr("id").replace("plan_","") : -1
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
			icon : { image: IMPASSE.url.iconTestCase }
		    },
		    test_suite : {
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
		    check_move : function (m) { 
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
		drag_target: false,
		drag_finish: function(data) {
		    return true;
		}
	    },
	    contextmenu: {
		select_node: true
	    }
	});
    $("#drop-area").floatmenu();
});

