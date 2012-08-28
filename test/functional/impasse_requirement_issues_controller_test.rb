require File.dirname(__FILE__) + '/../test_helper'

class ImpasseRequirementIssuesControllerTest < ActionController::TestCase
  self.fixture_path = File.expand_path(File.dirname(__FILE__) + '/../fixtures/')
  fixtures :projects, :users,
  :issues, :issue_categories, :issue_statuses

  # Replace this with your real tests.
  def setup
    @controller = ImpasseRequirementIssuesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end

  def test_requirements
    @request.session[:user_id] = 1
    Role.find(1).add_permission! :manage_testcase
    Project.find(2).enabled_module_names = [:impasse]
    get :index, :project_id => 'ecookbook'
    issues = assigns(:issues)
    assert issues && issues.size > 0
  end

  def test_assign_cases
    @request.session[:user_id] = 1
    Role.find(1).add_permission! :manage_testcase
    Project.find(2).enabled_module_names = [:impasse]

    post :add_test_case, :project_id => 'onlinestore', :issue_id => 4, :test_case_id => 3

    test_case = Impasse::TestCase.find(3)
    assert !test_case.nil?
    p test_case.requirement_issues
  end
end
