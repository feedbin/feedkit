require "test_helper"
require "tmpdir"
require "rbconfig"

class Feedkit::CurlTest < Minitest::Test
  def test_url_and_user_agent_are_literal_process_arguments
    Dir.mktmpdir("feedkit-curl-test") do |directory|
      arguments_path = File.join(directory, "arguments.json")
      executable = File.join(directory, "curl")
      File.write(executable, "#!#{RbConfig.ruby}\nrequire 'json'\nFile.write(ENV.fetch('FEEDKIT_TEST_ARGUMENTS'), JSON.dump(ARGV))\n")
      File.chmod(0755, executable)
      url = "https://example.com/a'b?query=hello&other=value"

      mock_env("PATH" => "#{directory}:#{ENV['PATH']}", "FEEDKIT_TEST_ARGUMENTS" => arguments_path, "FEEDKIT_USER_AGENT" => "Feedbin's crawler") do
        response = Feedkit::Curl.download(url)
        assert_equal ["--location", "--silent", "--user-agent", "Feedbin's crawler", "--output", response.path, "--url", url], JSON.parse(File.read(arguments_path))
      end
    end
  end
end
