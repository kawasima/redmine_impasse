require 'test_helper'

class ImpasseExecStepHistsControllerTest < ActionController::TestCase
  setup do
    @impasse_exec_step_hist = impasse_exec_step_hists(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:impasse_exec_step_hists)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create impasse_exec_step_hist" do
    assert_difference('ImpasseExecStepHist.count') do
      post :create, impasse_exec_step_hist: {  }
    end

    assert_redirected_to impasse_exec_step_hist_path(assigns(:impasse_exec_step_hist))
  end

  test "should show impasse_exec_step_hist" do
    get :show, id: @impasse_exec_step_hist
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @impasse_exec_step_hist
    assert_response :success
  end

  test "should update impasse_exec_step_hist" do
    put :update, id: @impasse_exec_step_hist, impasse_exec_step_hist: {  }
    assert_redirected_to impasse_exec_step_hist_path(assigns(:impasse_exec_step_hist))
  end

  test "should destroy impasse_exec_step_hist" do
    assert_difference('ImpasseExecStepHist.count', -1) do
      delete :destroy, id: @impasse_exec_step_hist
    end

    assert_redirected_to impasse_exec_step_hists_path
  end
end
