# encoding: utf-8
require "spec_helper"

describe TrueClass do
  let(:obj)  { true }
  let(:bson) { 1.chr }

  it_behaves_like "a serializable bson element"
end