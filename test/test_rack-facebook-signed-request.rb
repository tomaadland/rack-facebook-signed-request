require 'helper'
require 'sample_app'

class TestRackFacebookSignedRequest < Test::Unit::TestCase

  include Rack::Facebook
  include Rack::Test::Methods

  def app
    SampleApp.new
  end

  should "encode base 64 url properly" do
    assert_equal 'aHVtYmFiYQ', SignedRequest.base64_url_encode('humbaba')
  end

  should "decode base64 url properly" do
    assert_equal 'humbaba', SignedRequest.base64_url_decode('aHVtYmFiYQ')
    assert_equal 'tutto il buono del pane', SignedRequest.base64_url_decode(SignedRequest.base64_url_encode('tutto il buono del pane'))
  end

  should "decode payload properly" do
    hsh = {"algorithm"=>"HMAC-SHA256", "issued_at"=>1302716199, "page"=>{"id"=>"199388336751153", "liked"=>false, "admin"=>true}, "user"=>{"country"=>"fr", "locale"=>"en_US", "age"=>{"min"=>21}}}
    payload = 'eyJhbGdvcml0aG0iOiJITUFDLVNIQTI1NiIsImlzc3VlZF9hdCI6MTMwMjcxNjE5OSwicGFnZSI6eyJpZCI6IjE5OTM4ODMzNjc1MTE1MyIsImxpa2VkIjpmYWxzZSwiYWRtaW4iOnRydWV9LCJ1c2VyIjp7ImNvdW50cnkiOiJmciIsImxvY2FsZSI6ImVuX1VTIiwiYWdlIjp7Im1pbiI6MjF9fX0'
    assert_equal hsh, SignedRequest.json_from_payload(payload)
  end

  should "validate valid signed request" do
    assert SignedRequest.valid_signature?('a1cb502206f613a14d74c865aa45ca24', 'o04mPk-g8Un8Xqds7r3XTRjWONSbHpRUFHl5JJd6IEU', 'eyJhbGdvcml0aG0iOiJITUFDLVNIQTI1NiIsImlzc3VlZF9hdCI6MTMwMjcxNjE5OSwicGFnZSI6eyJpZCI6IjE5OTM4ODMzNjc1MTE1MyIsImxpa2VkIjpmYWxzZSwiYWRtaW4iOnRydWV9LCJ1c2VyIjp7ImNvdW50cnkiOiJmciIsImxvY2FsZSI6ImVuX1VTIiwiYWdlIjp7Im1pbiI6MjF9fX0')
  end

  should "not validate invalid signature" do
    assert !SignedRequest.valid_signature?('a1cb502206f613a14d74c865aa45ca24', 'o04mPk-g8Un8Xqds7r3XTRjWONSbHpRUFHl5JJd6IEU', 'INURDATAeyJhbGdvcml0aG0iOiJITUFDLVNIQTI1NiIsImlzc3VlZF9hdCI6MTMwMjcxNjE5OSwicGFnZSI6eyJpZCI6IjE5OTM4ODMzNjc1MTE1MyIsImxpa2VkIjpmYWxzZSwiYWRtaW4iOnRydWV9LCJ1c2VyIjp7ImNvdW50cnkiOiJmciIsImxvY2FsZSI6ImVuX1VTIiwiYWdlIjp7Im1pbiI6MjF9fX0')
  end
  
  context "multiple apps" do 
    should "return secret string if only one app is configured" do
      sreq = SignedRequest.new(app, :secret => "supersecret")
      assert_equal "supersecret", sreq.secret
    end
    
    should "return the options hash if send in more then one app secret key" do
      apps = {:app_1 => {:secret => "secrett"}, :app_2 => {:secret => "yesyes"}}
      sreq = SignedRequest.new(app,apps)
      assert_equal apps, sreq.secret
    end

    should "validate valid signed request when configured with multiple apps" do
      apps = {:app_1 => {:secret => "secret"}, :app_2 => {:secret => "a1cb502206f613a14d74c865aa45ca24"}}
      assert SignedRequest.valid_signature?(apps, 'o04mPk-g8Un8Xqds7r3XTRjWONSbHpRUFHl5JJd6IEU', 'eyJhbGdvcml0aG0iOiJITUFDLVNIQTI1NiIsImlzc3VlZF9hdCI6MTMwMjcxNjE5OSwicGFnZSI6eyJpZCI6IjE5OTM4ODMzNjc1MTE1MyIsImxpa2VkIjpmYWxzZSwiYWRtaW4iOnRydWV9LCJ1c2VyIjp7ImNvdW50cnkiOiJmciIsImxvY2FsZSI6ImVuX1VTIiwiYWdlIjp7Im1pbiI6MjF9fX0')
    end
  end

end
