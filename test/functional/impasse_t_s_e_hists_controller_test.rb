require 'test_helper'

class ImpasseTSEHistsControllerTest < ActionController::TestCase
  setup do
    @impasse_t_s_e_hist = impasse_t_s_e_hists(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:impasse_t_s_e_hists)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create impasse_t_s_e_hist" do
    assert_difference('ImpasseTSEHist.count') do
      post :create, impasse_t_s_e_hist: {  }
    end

    assert_redirected_to impasse_t_s_e_hist_path(assigns(:impasse_t_s_e_hist))
  end

  test "should show impasse_t_s_e_hist" do
    get :show, id: @impasse_t_s_e_hist
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @impasse_t_s_e_hist
    assert_response :success
  end

  test "should update impasse_t_s_e_hist" do
    put :update, id: @impasse_t_s_e_hist, impasse_t_s_e_hist: {  }
    assert_redirected_to impasse_t_s_e_hist_path(assigns(:impasse_t_s_e_hist))
  end

  test "should destroy impasse_t_s_e_hist" do
    assert_difference('ImpasseTSEHist.count', -1) do
      delete :destroy, id: @impasse_t_s_e_hist
    end

    assert_redirected_to impasse_t_s_e_hists_path
  end
end
