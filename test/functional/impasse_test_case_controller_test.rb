require File.dirname(__FILE__) + '/../test_helper'

class ImpasseTestCaseControllerTest < ActionController::TestCase
  self.fixture_path = File.expand_path(File.dirname(__FILE__) + '/../fixtures/')
  fixtures :projects, :users,
  :impasse_nodes, :impasse_test_suites, :impasse_test_cases, :impasse_test_steps,
  :impasse_keywords, :impasse_node_keywords

  # Replace this with your real tests.
  def setup
    @controller = ImpasseTestCaseController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end

  def test_copy_to_another_project
    @request.session[:user_id] = 1
    Role.find(1).add_permission! :manage_testcase
    Project.find(2).enabled_module_names = [:impasse]
    post :copy_to_another_project, :project_id => 'onlinestore', :dest_project_id => 'ecookbook', :node_ids => [3]
    assert_redirected_to :action => :index, :project_id => 'ecookbook'
    root = Impasse::Node.find_by(:name => 'ecookbook', :node_type_id => 1)
    assert !root.nil?
    assert root.children.size == 1
    suite = root.children[0]
    assert suite.children.size == 1

    testcase_node = suite.children[0]
    testcase = Impasse::TestCase.find(testcase_node.id)
    assert_equal 1, testcase.test_steps.size
  end
end
