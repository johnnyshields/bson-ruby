# frozen_string_literal: true
# rubocop:todo all
# Copyright (C) 2021 MongoDB Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "spec_helper"

# BSON::Document ActiveSupport extensions
describe BSON::Document do
  require_active_support

  describe '#symbolize_keys' do
    let(:document) do
      BSON::Document.new('key1' => 'value1', 'key2' => 'value2')
    end

    let(:result) do
      document.symbolize_keys
    end

    it 'returns a Hash, not a BSON::Document' do
      expect(result).to be_a(Hash)
      expect(result).not_to be_a(BSON::Document)
    end

    it 'converts string keys to symbols' do
      expect(result).to eq({ key1: 'value1', key2: 'value2' })
    end

    it 'does not modify the original document' do
      result
      expect(document).to eq(BSON::Document.new('key1' => 'value1', 'key2' => 'value2'))
    end

    context 'with nested documents' do
      let(:document) do
        BSON::Document.new('key1' => BSON::Document.new('inner' => 'value'))
      end

      let(:result) do
        document.symbolize_keys
      end

      it 'does not convert keys in nested documents' do
        expect(result[:key1]).to eq({ 'inner' => 'value' })
      end

      it 'converts nested BSON::Documents to plain Hashes' do
        expect(result[:key1]).to be_a(Hash)
        expect(result[:key1]).not_to be_a(BSON::Document)
      end
    end
  end

  describe '#symbolize_keys!' do
    let(:document) do
      BSON::Document.new('key1' => 'value1', 'key2' => 'value2')
    end

    it 'raises ArgumentError' do
      expect { document.symbolize_keys! }.to raise_error(ArgumentError, /symbolize_keys! is not supported/)
    end
  end

  describe '#deep_symbolize_keys' do
    let(:document) do
      BSON::Document.new('key1' => 'value1', 'key2' => BSON::Document.new('inner' => 'value'))
    end

    let(:result) do
      document.deep_symbolize_keys
    end

    it 'returns a Hash, not a BSON::Document' do
      expect(result).to be_a(Hash)
      expect(result).not_to be_a(BSON::Document)
    end

    it 'converts string keys to symbols at all levels' do
      expect(result).to eq({ key1: 'value1', key2: { inner: 'value' } })
    end

    it 'does not modify the original document' do
      result
      expect(document).to eq(BSON::Document.new('key1' => 'value1', 'key2' => BSON::Document.new('inner' => 'value')))
    end
  end

  describe '#deep_symbolize_keys!' do
    let(:document) do
      BSON::Document.new('key1' => 'value1', 'key2' => BSON::Document.new('inner' => 'value'))
    end

    it 'raises ArgumentError' do
      expect { document.deep_symbolize_keys! }.to raise_error(ArgumentError, /deep_symbolize_keys! is not supported/)
    end
  end

  describe '#stringify_keys' do
    let(:document) do
      BSON::Document.new(:key1 => 'value1', 'key2' => 'value2')
    end

    let(:result) do
      document.stringify_keys
    end

    it 'returns a new BSON::Document' do
      expect(result).to be_a(BSON::Document)
      expect(result).to_not be(document)
    end
  end

  describe '#stringify_keys!' do
    let(:document) do
      BSON::Document.new(:key1 => 'value1', 'key2' => 'value2')
    end

    it 'returns self' do
      expect(document.stringify_keys).to eq document
    end
  end

  describe '#deep_stringify_keys' do
    let(:document) do
      BSON::Document.new(:key1 => 'value1', :key2 => BSON::Document.new(:inner => 'value'))
    end

    let(:result) do
      document.deep_stringify_keys
    end

    it 'returns a Hash' do
      expect(result).to be_a(Hash)
    end

    it 'converts all keys to strings at all levels' do
      expect(result).to eq({ 'key1' => 'value1', 'key2' => { 'inner' => 'value' } })
    end

    it 'converts nested documents to Hash' do
      expect(result['key2']).to be_a(Hash)
    end
  end

  describe '#deep_stringify_keys!' do
    let(:document) do
      BSON::Document.new(:key1 => 'value1', 'key2' => 'value2')
    end

    it 'is an alias for #stringify_keys!' do
      expect(document.method(:deep_stringify_keys!)).to eq(document.method(:stringify_keys!))
    end

    it 'returns self' do
      expect(document.stringify_keys).to eq document
    end
  end

  describe '#slice!' do
    context 'with a single-level document' do
      let(:document) do
        BSON::Document.new('key1' => 'value1', 'key2' => 'value2', 'key3' => 'value3')
      end

      let(:result) do
        document.slice!('key1', 'key3')
      end

      it 'returns a new BSON::Document with removed keys' do
        expect(result).to be_a(BSON::Document)
        expect(result).to eq(BSON::Document.new('key2' => 'value2'))
      end

      it 'modifies the original document' do
        result
        expect(document).to eq(BSON::Document.new('key1' => 'value1', 'key3' => 'value3'))
      end
    end

    context 'when some keys do not exist' do
      let(:document) do
        BSON::Document.new('key1' => 'value1', 'key2' => 'value2')
      end

      let(:result) do
        document.slice!('key1', 'nonexistent')
      end

      it 'returns a document with the keys that were removed' do
        expect(result).to eq(BSON::Document.new('key2' => 'value2'))
      end

      it 'modifies the original document' do
        result
        expect(document).to eq(BSON::Document.new('key1' => 'value1'))
      end
    end

    context 'with symbol keys' do
      let(:document) do
        BSON::Document.new(key1: 'value1', key2: 'value2')
      end

      let(:result) do
        document.slice!('key1')
      end

      it 'returns a document with the keys that were removed' do
        expect(result).to eq(BSON::Document.new('key2' => 'value2'))
      end

      it 'modifies the original document' do
        result
        expect(document).to eq(BSON::Document.new('key1' => 'value1'))
      end
    end
  end
end
