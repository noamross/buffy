require_relative "../spec_helper.rb"

describe WelcomeTemplateResponder do

  subject do
    described_class
  end

  describe "listening" do
    before { @responder = subject.new({bot_github_user: "botsci"}, {}) }

    it "should listen to new issues" do
      expect(@responder.event_action).to eq("issues.opened")
    end

    it "should not define regex" do
      expect(@responder.event_regex).to be_nil
    end
  end

  describe "#process_message" do
    before do
      @responder = subject.new({ bot_github_user: 'botsci' }, { template_file: "test.md", data_from_issue: ["reviewer"] })
      @responder.context = OpenStruct.new(issue_id: 5,
                                          repo: "openjournals/buffy",
                                          sender: "user33",
                                          issue_body: "Test Software Review\n\n<!--reviewer-->@xuanxu<!--end-reviewer-->")
      disable_github_calls_for(@responder)
    end

    it "should populate locals" do
      expected_locals = { issue_id: 5, bot_name: "botsci", repo: "openjournals/buffy", sender: "user33", "reviewer" => "@xuanxu" }

      expect(@responder).to receive(:respond_external_template).with("test.md", expected_locals)
      @responder.process_message("")
    end

    it "should respond to github using the custom template" do
      expect(URI).to receive(:parse).and_return(URI("buf.fy"))
      expect_any_instance_of(URI::Generic).to receive(:read).once.and_return("Welcome {{sender}}, {{reviewer}} will review your software")

      expected_reply = "Welcome user33, @xuanxu will review your software"
      expect(@responder).to receive(:respond).with(expected_reply)
      @responder.process_message("")
    end
  end

  describe "misconfiguration" do
    it "should raise error if template_file is missing from config" do
      responder = subject.new({ bot_github_user: "botsci" }, {})
      expect {
        responder.process_message("")
      }.to raise_error "Configuration Error in WelcomeTemplateResponder: No value for template_file."
    end

    it "should raise error if template_file is empty" do
      responder = subject.new({ bot_github_user: "botsci" }, { template_file: "    " })
      expect {
        responder.process_message("")
      }.to raise_error "Configuration Error in WelcomeTemplateResponder: No value for template_file."
    end
  end
end