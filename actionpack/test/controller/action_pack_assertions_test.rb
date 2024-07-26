require File.dirname(__FILE__) + '/../abstract_unit'

# a controller class to facilitate the tests
class ActionPackAssertionsController < ActionController::Base

  # this does absolutely nothing
  def nothing() render_text ""; end

  # a standard template
  def hello_world() render "test/hello_world"; end

  # a standard template
  def hello_xml_world() render "test/hello_xml_world"; end
 
  # a redirect to an internal location
  def redirect_internal() redirect_to "nothing"; end

  # a redirect to an external location
  def redirect_external() redirect_to_url "http://www.rubyonrails.org"; end
  
  # a 404
  def response404() render_text "", "404 AWOL"; end

  # a 500
  def response500() render_text "", "500 Sorry"; end

  # a fictional 599
  def response599() render_text "", "599 Whoah!"; end

  # putting stuff in the flash
  def flash_me
    flash['hello'] = 'my name is inigo montoya...'
    render_text "Inconceivable!"
  end

  # we have a flash, but nothing is in it
  def flash_me_naked
    flash.clear
    render_text "wow!"
  end

  # assign some template instance variables
  def assign_this
    @howdy = "ho"
    render_text "Mr. Henke"
  end

  def render_based_on_parameters
    render_text "Mr. #{@params["name"]}"
  end

  # puts something in the session
  def session_stuffing
    session['xmas'] = 'turkey'
    render_text "ho ho ho"
  end

  # 911
  def rescue_action(e) raise; end
    
end

# ---------------------------------------------------------------------------


# tell the controller where to find its templates but start from parent 
# directory of test_request_response to simulate the behaviour of a 
# production environment
ActionPackAssertionsController.template_root = File.dirname(__FILE__) + "/../fixtures/"


# a test case to exercise the new capabilities TestRequest & TestResponse
class ActionPackAssertionsControllerTest < Test::Unit::TestCase  
  # let's get this party started  
  def setup
    @controller = ActionPackAssertionsController.new
    @request, @response = ActionController::TestRequest.new, ActionController::TestResponse.new
  end
 
  # -- assertion-based testing ------------------------------------------------

  # test the session assertion to make sure something is there.
  def test_assert_session_has
    process :session_stuffing
    assert_session_has 'xmas'
    assert_session_has_no 'halloween'
  end

  # test the assertion of goodies in the template
  def test_assert_template_has
    process :assign_this
    assert_template_has 'howdy'
  end

  # test the assertion for goodies that shouldn't exist in the template
  def test_assert_template_has_no
    process :nothing
    assert_template_has_no 'maple syrup'
    assert_template_has_no 'howdy'
  end
  
  # test the redirection assertions
  def test_assert_redirect
    process :redirect_internal
    assert_redirect
  end

  # test the redirect url string
  def test_assert_redirect_url
    process :redirect_external
    assert_redirect_url 'http://www.rubyonrails.org'
  end

  # test the redirection pattern matching on a string
  def test_assert_redirect_url_match_string
    process :redirect_external
    assert_redirect_url_match 'rails.org'
  end
  
  # test the redirection pattern matching on a pattern
  def test_assert_redirect_url_match_pattern
    process :redirect_external
    assert_redirect_url_match /ruby/
  end
  
  # test the flash-based assertions with something is in the flash
  def test_flash_assertions_full
    process :flash_me
    assert @response.has_flash_with_contents?
    assert_flash_exists
    assert ActionController::TestResponse.assertion_target.has_flash_with_contents?
    assert_flash_not_empty
    assert_flash_has 'hello'
    assert_flash_has_no 'stds'
  end

  # test the flash-based assertions with no flash at all
  def test_flash_assertions_negative
    process :nothing
    assert_flash_not_exists
    assert_flash_empty
    assert_flash_has_no 'hello'
    assert_flash_has_no 'qwerty'
  end
  
  # test the assert_rendered_file 
  def test_assert_rendered_file
    process :hello_world
    assert_rendered_file 'test_request_response/hello_world'
    assert_rendered_file 'hello_world'
    assert_rendered_file
  end
  
  # test the assert_success assertion
  def test_assert_success
    process :nothing
    assert_success
  end
  
  # -- standard request/reponse object testing --------------------------------
 
  # ensure our session is working properly
  def test_session_objects
    process :session_stuffing
    assert @response.has_session_object?('xmas')
    assert !@response.has_session_object?('easter')
  end
  
  # make sure that the template objects exist
  def test_template_objects_alive
    process :assign_this
    assert !@response.has_template_object?('hi')
    assert @response.has_template_object?('howdy')
  end
  
  # make sure we don't have template objects when we shouldn't
  def test_template_object_missing
    process :nothing
    assert_nil @response.template_objects['howdy']
  end

  # check the empty flashing
  def test_flash_me_naked
    process :flash_me_naked
    assert @response.has_flash?
    assert !@response.has_flash_with_contents?
  end

  # check if we have flash objects
  def test_flash_haves
    process :flash_me
    assert @response.has_flash?
    assert @response.has_flash_with_contents?
    assert @response.has_flash_object?('hello')
  end

  # ensure we don't have flash objects
  def test_flash_have_nots
    process :nothing
    assert !@response.has_flash?
    assert !@response.has_flash_with_contents?
    assert_nil @response.flash['hello']
  end
  
  
  # check if we were rendered by a file-based template? 
  def test_rendered_action
    process :nothing
    assert !@response.rendered_with_file?

    process :hello_world
    assert @response.rendered_with_file?
    assert 'hello_world', @response.rendered_file
  end
  
  # check the redirection location
  def test_redirection_location
    process :redirect_internal
    assert_equal 'nothing', @response.redirect_url

    process :redirect_external
    assert_equal 'http://www.rubyonrails.org', @response.redirect_url

    process :nothing
    assert_nil @response.redirect_url
  end
  
 
  # check server errors 
  def test_server_error_response_code
    process :response500
    assert @response.server_error?
    
    process :response599
    assert @response.server_error?
    
    process :response404
    assert !@response.server_error?
  end
  
  # check a 404 response code
  def test_missing_response_code
    process :response404
    assert @response.missing?
  end

  # check to see if our redirection matches a pattern
  def test_redirect_url_match
    process :redirect_external
    assert @response.redirect?
    assert @response.redirect_url_match?("rubyonrails")
    assert @response.redirect_url_match?(/rubyonrails/)
    assert !@response.redirect_url_match?("phpoffrails")
    assert !@response.redirect_url_match?(/perloffrails/)
  end
  
  # check for a redirection
  def test_redirection
    process :redirect_internal
    assert @response.redirect?

    process :redirect_external
    assert @response.redirect?

    process :nothing
    assert !@response.redirect?
  end
  
  # check a successful response code
  def test_successful_response_code
    process :nothing
    assert @response.success?
  end 
  
  # a basic check to make sure we have a TestResponse object
  def test_has_response
    process :nothing
    assert_kind_of ActionController::TestResponse, @response
  end
  
  def test_render_based_on_parameters
    process :render_based_on_parameters, "name" => "David"
    assert_equal "Mr. David", @response.body
  end

  def test_simple_one_element_xpath_match
    process :hello_xml_world
    assert_template_xpath_match('//title', "Hello World")
  end

  def test_array_of_elements_in_xpath_match
    process :hello_xml_world
    assert_template_xpath_match('//p', %w( abes monks wiseguys ))
  end
end