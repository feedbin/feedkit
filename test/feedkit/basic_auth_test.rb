require "test_helper"

class Feedkit::BasicAuthTest < Minitest::Test
  def test_should_get_username_and_password
    username = "email@example.com"
    password = "[pass:word]"
    url = "email%40example.com:%5Bpass%3Aword%5D@www.example.com/atom.xml"

    result = Feedkit::BasicAuth.parse(url)
    assert_equal(username, result.username)
    assert_equal(password, result.password)
    assert_equal("http://www.example.com/atom.xml", result.url)
  end
end
