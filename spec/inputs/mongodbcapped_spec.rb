# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/inputs/mongodbcapped"

describe LogStash::Inputs::MongoDBCapped do

  let(:empty_config) {{}}
  let(:server_only_config) {{
    "uri" => "mongodb://localhost/mydb"
  }}
  let(:base_config) {{
    "uri" => "mongodb://localhost/mydb",
    "collection" => "foobar",
  }}

  it_behaves_like "an interruptible input plugin" do
    let(:config) {base_config}
  end

  it "should fail without a server config" do
    input = LogStash::Plugin.lookup("input", "mongodbcapped").new({})
    expect {input.register}.to raise_error
  end

  it "should fail without a collection config" do
    input = LogStash::Plugin.lookup("input", "mongodbcapped").new(server_only_config)
    expect {input.register}.to raise_error
  end

end
