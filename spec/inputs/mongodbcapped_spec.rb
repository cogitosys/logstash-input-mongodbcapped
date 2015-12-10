# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/inputs/mongodbcapped"

describe LogStash::Inputs::MongoDBCapped do

  let(:empty_config) {{}}
  let(:empty_collection_config) {{
    "server" => "mongodb://localhost/mydb",
    "collections" => [],
  }}
  let(:single_collection_config) {{
    "server" => "mongodb://localhost/mydb",
    "collections" => "capped",
  }}
  let(:multi_collection_config) {{
    "server" => "mongodb://localhost",
    "collections" => ["foo/bar","baz/quux"],
  }}
  let(:override_database_config) {{
    "server" => "mongodb://localhost/mydb",
    "collections" => ["foo","bar/baz"],
  }}

  it_behaves_like "an interruptible input plugin" do
    # NOTE: this will fail unless you've created a capped collection called "capped" in the localhosts' "mydb" mongo db database
    # Or at least until Mongo includes a mocked implementation of their client so we don't have to worry about these things
    let(:config) {single_collection_config}
  end

  it "should fail without a server config" do
    expect {LogStash::Plugin.lookup("input", "mongodbcapped").new(empty_config)}.to raise_error
  end

  it "should fail without a collection to watch" do
    input = LogStash::Plugin.lookup("input", "mongodbcapped").new(empty_collection_config)
    expect {input.register}.to raise_error
  end

  it "should configure a uri set database correctly" do
    input = LogStash::Plugin.lookup("input", "mongodbcapped").new(single_collection_config)
    input.register
    expect(input.instance_variable_get(:@collections)).to eq [["mydb", "capped"]]
  end

  it "should configure multiple collections, across databases" do
    input = LogStash::Plugin.lookup("input", "mongodbcapped").new(multi_collection_config)
    input.register
    expect(input.instance_variable_get(:@collections)).to eq [["foo", "bar"], ["baz", "quux"]]
  end

  it "should configure database overrides" do
    input = LogStash::Plugin.lookup("input", "mongodbcapped").new(override_database_config)
    input.register
    expect(input.instance_variable_get(:@collections)).to eq [["mydb", "foo"], ["bar", "baz"]]
  end

end
