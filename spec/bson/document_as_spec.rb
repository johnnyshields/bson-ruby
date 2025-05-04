# frozen_string_literal: true
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

require 'spec_helper'

# BSON::Document tests for ActiveSupport Hash extension method behaviors
describe BSON::Document do
  require_active_support

  describe '#symbolize_keys' do
    let(:document) do
      described_class.new('key1' => 'value1', 'key2' => 'value2')
    end

    let(:result) do
      document.symbolize_keys
    end

    it 'returns a Hash, not a BSON::Document' do
      expect(result).to be_a(Hash)
      expect(result).not_to be_a(described_class)
    end

    it 'converts string keys to symbols' do
      expect(result).to eq({ key1: 'value1', key2: 'value2' })
    end

    it 'does not modify the original document' do
      result
      expect(document).to eq(described_class.new('key1' => 'value1', 'key2' => 'value2'))
    end

    context 'with nested documents' do
      let(:document) do
        described_class.new('key1' => described_class.new('inner' => 'value'))
      end

      let(:result) do
        document.symbolize_keys
      end

      it 'does not convert keys in nested documents' do
        expect(result[:key1]).to eq({ 'inner' => 'value' })
      end

      it 'converts nested described_classs to plain Hashes' do
        expect(result[:key1]).to be_a(Hash)
        expect(result[:key1]).not_to be_a(described_class)
      end
    end
  end

  describe '#symbolize_keys!' do
    let(:document) do
      described_class.new('key1' => 'value1', 'key2' => 'value2')
    end

    it 'raises ArgumentError' do
      expect { document.symbolize_keys! }.to raise_error(ArgumentError, /symbolize_keys! is not supported/)
    end
  end

  describe '#deep_symbolize_keys' do
    let(:document) do
      described_class.new('key1' => 'value1', 'key2' => described_class.new('inner' => 'value'))
    end

    let(:result) do
      document.deep_symbolize_keys
    end

    it 'returns a Hash, not a BSON::Document' do
      expect(result).to be_a(Hash)
      expect(result).not_to be_a(described_class)
    end

    it 'converts string keys to symbols at all levels' do
      expect(result).to eq({ key1: 'value1', key2: { inner: 'value' } })
    end

    it 'does not modify the original document' do
      result
      expect(document).to eq(described_class.new('key1' => 'value1', 'key2' => described_class.new('inner' => 'value')))
    end
  end

  describe '#deep_symbolize_keys!' do
    let(:document) do
      described_class.new('key1' => 'value1', 'key2' => described_class.new('inner' => 'value'))
    end

    it 'raises ArgumentError' do
      expect { document.deep_symbolize_keys! }.to raise_error(ArgumentError, /deep_symbolize_keys! is not supported/)
    end
  end

  describe '#stringify_keys' do
    let(:document) do
      described_class.new(:key1 => 'value1', 'key2' => 'value2')
    end

    let(:result) do
      document.stringify_keys
    end

    it 'returns a new BSON::Document' do
      expect(result).to be_a(described_class)
      expect(result).to_not be(document)
    end
  end

  describe '#stringify_keys!' do
    let(:document) do
      described_class.new(:key1 => 'value1', 'key2' => 'value2')
    end

    it 'returns self' do
      expect(document.stringify_keys).to eq document
    end
  end

  describe '#deep_stringify_keys' do
    let(:document) do
      described_class.new(:key1 => 'value1', :key2 => described_class.new(:inner => 'value'))
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
      described_class.new(:key1 => 'value1', 'key2' => 'value2')
    end

    it 'returns self' do
      expect(document.stringify_keys).to eq document
    end
  end

  describe '#slice!' do
    context 'with a single-level document' do
      let(:document) do
        described_class.new('key1' => 'value1', 'key2' => 'value2', 'key3' => 'value3')
      end

      let(:result) do
        document.slice!('key1', 'key3')
      end

      it 'returns a new BSON::Document with removed keys' do
        expect(result).to be_a(described_class)
        expect(result).to eq(described_class.new('key2' => 'value2'))
      end

      it 'modifies the original document' do
        result
        expect(document).to eq(described_class.new('key1' => 'value1', 'key3' => 'value3'))
      end
    end

    context 'when some keys do not exist' do
      let(:document) do
        described_class.new('key1' => 'value1', 'key2' => 'value2')
      end

      let(:result) do
        document.slice!('key1', 'nonexistent')
      end

      it 'returns a document with the keys that were removed' do
        expect(result).to eq(described_class.new('key2' => 'value2'))
      end

      it 'modifies the original document' do
        result
        expect(document).to eq(described_class.new('key1' => 'value1'))
      end
    end

    context 'with symbol keys' do
      let(:document) do
        described_class.new(key1: 'value1', key2: 'value2')
      end

      let(:result) do
        document.slice!('key1')
      end

      it 'returns a document with the keys that were removed' do
        expect(result).to eq(described_class.new('key2' => 'value2'))
      end

      it 'modifies the original document' do
        result
        expect(document).to eq(described_class.new('key1' => 'value1'))
      end
    end
  end

  describe '#deep_merge' do
    let(:document) do
      described_class.new('key1' => 'value1', 'key2' => 'value2')
    end

    context 'when merging with a simple hash' do
      let(:other) do
        { 'key2' => 'new_value', 'key3' => 'value3' }
      end

      let(:result) do
        document.deep_merge(other)
      end

      it 'returns a new BSON::Document' do
        expect(result).to be_a(described_class)
        expect(result).not_to be(document)
      end

      it 'includes all keys from both documents' do
        expect(result.keys).to include('key1', 'key2', 'key3')
      end

      it 'overwrites values for duplicate keys' do
        expect(result['key2']).to eq('new_value')
      end

      it 'does not modify the original document' do
        expect(document['key2']).to eq('value2')
        expect(document.keys).not_to include('key3')
      end
    end

    context 'when merging with a nested hash' do
      let(:document) do
        described_class.new(
          'key1' => 'value1',
          'nested' => described_class.new(
            'inner1' => 'value1',
            'inner2' => 'value2'
          )
        )
      end

      let(:other) do
        {
          'key2' => 'value2',
          'nested' => {
            'inner2' => 'new_value',
            'inner3' => 'value3'
          }
        }
      end

      let(:result) do
        document.deep_merge(other)
      end

      it 'returns a new BSON::Document' do
        expect(result).to be_a(described_class)
        expect(result).not_to be(document)
      end

      it 'includes top-level keys from both documents' do
        expect(result.keys).to include('key1', 'key2', 'nested')
      end

      it 'deeply merges nested documents' do
        expect(result['nested'].keys).to include('inner1', 'inner2', 'inner3')
        expect(result['nested']['inner1']).to eq('value1')
        expect(result['nested']['inner2']).to eq('new_value')
        expect(result['nested']['inner3']).to eq('value3')
      end

      it 'returns nested documents as described_classs' do
        expect(result['nested']).to be_a(described_class)
      end

      it 'does not modify the original document' do
        expect(document['nested']['inner2']).to eq('value2')
        expect(document['nested'].keys).not_to include('inner3')
      end
    end

    context 'when merging with deeply nested hashes' do
      let(:document) do
        described_class.new(
          'level1' => described_class.new(
            'level2' => described_class.new(
              'level3' => described_class.new(
                'a' => 1,
                'b' => 2
              )
            )
          )
        )
      end

      let(:other) do
        {
          'level1' => {
            'level2' => {
              'level3' => {
                'b' => 3,
                'c' => 4
              },
              'new_key' => 'value'
            }
          }
        }
      end

      let(:result) do
        document.deep_merge(other)
      end

      it 'merges documents at all levels' do
        expect(result['level1']['level2']['level3']['a']).to eq(1)
        expect(result['level1']['level2']['level3']['b']).to eq(3)
        expect(result['level1']['level2']['level3']['c']).to eq(4)
        expect(result['level1']['level2']['new_key']).to eq('value')
      end

      it 'returns BSON::Document at all nested levels' do
        expect(result['level1']).to be_a(described_class)
        expect(result['level1']['level2']).to be_a(described_class)
        expect(result['level1']['level2']['level3']).to be_a(described_class)
      end
    end

    context 'when merging with arrays' do
      let(:document) do
        described_class.new(
          'key1' => 'value1',
          'array' => [1, 2, 3],
          'nested' => described_class.new(
            'array' => [4, 5, 6]
          )
        )
      end

      let(:other) do
        {
          'key2' => 'value2',
          'array' => [7, 8, 9],
          'nested' => {
            'array' => [10, 11, 12]
          }
        }
      end

      let(:result) do
        document.deep_merge(other)
      end

      it 'replaces arrays instead of merging them' do
        expect(result['array']).to eq([7, 8, 9])
        expect(result['nested']['array']).to eq([10, 11, 12])
      end
    end

    context 'when merging with non-hash values' do
      let(:document) do
        described_class.new(
          'key1' => 'value1',
          'key2' => described_class.new('inner' => 'value')
        )
      end

      let(:other) do
        {
          'key1' => 'new_value',
          'key2' => 'not_a_hash'
        }
      end

      let(:result) do
        document.deep_merge(other)
      end

      it 'overwrites non-hash values' do
        expect(result['key1']).to eq('new_value')
        expect(result['key2']).to eq('not_a_hash')
      end
    end

    context 'when a block is provided' do
      let(:document) do
        described_class.new(
          'key1' => 'value1',
          'nested' => described_class.new(
            'inner' => 5
          )
        )
      end

      let(:other) do
        {
          'key1' => 'new_value',
          'nested' => {
            'inner' => 10
          }
        }
      end

      let(:result) do
        document.deep_merge(other) do |key, old_value, new_value|
          if key == 'inner' && old_value.is_a?(Integer) && new_value.is_a?(Integer)
            old_value + new_value
          else
            new_value
          end
        end
      end

      it 'applies the block to resolve conflicts' do
        expect(result['key1']).to eq('new_value')
        expect(result['nested']['inner']).to eq(15) # 5 + 10
      end
    end
  end

  describe '#deep_merge!' do
    let(:document) do
      described_class.new('key1' => 'value1', 'key2' => 'value2')
    end

    context 'when merging with a simple hash' do
      let(:other) do
        { 'key2' => 'new_value', 'key3' => 'value3' }
      end

      let(:result) do
        document.deep_merge!(other)
      end

      it 'returns self' do
        expect(result).to be(document)
      end

      it 'includes all keys from both documents' do
        result
        expect(document.keys).to include('key1', 'key2', 'key3')
      end

      it 'overwrites values for duplicate keys' do
        result
        expect(document['key2']).to eq('new_value')
      end
    end

    context 'when merging with a nested hash' do
      let(:document) do
        described_class.new(
          'key1' => 'value1',
          'nested' => described_class.new(
            'inner1' => 'value1',
            'inner2' => 'value2'
          )
        )
      end

      let(:other) do
        {
          'key2' => 'value2',
          'nested' => {
            'inner2' => 'new_value',
            'inner3' => 'value3'
          }
        }
      end

      let(:result) do
        document.deep_merge!(other)
      end

      it 'returns self' do
        expect(result).to be(document)
      end

      it 'includes top-level keys from both documents' do
        result
        expect(document.keys).to include('key1', 'key2', 'nested')
      end

      it 'deeply merges nested documents' do
        result
        expect(document['nested'].keys).to include('inner1', 'inner2', 'inner3')
        expect(document['nested']['inner1']).to eq('value1')
        expect(document['nested']['inner2']).to eq('new_value')
        expect(document['nested']['inner3']).to eq('value3')
      end

      it 'returns nested documents as BSON::Document' do
        result
        expect(document['nested']).to be_a(described_class)
      end
    end

    context 'when merging with deeply nested hashes' do
      let(:document) do
        described_class.new(
          'level1' => described_class.new(
            'level2' => described_class.new(
              'level3' => described_class.new(
                'a' => 1,
                'b' => 2
              )
            )
          )
        )
      end

      let(:other) do
        {
          'level1' => {
            'level2' => {
              'level3' => {
                'b' => 3,
                'c' => 4
              },
              'new_key' => 'value'
            }
          }
        }
      end

      let(:result) do
        document.deep_merge!(other)
      end

      it 'merges documents at all levels' do
        result
        expect(document['level1']['level2']['level3']['a']).to eq(1)
        expect(document['level1']['level2']['level3']['b']).to eq(3)
        expect(document['level1']['level2']['level3']['c']).to eq(4)
        expect(document['level1']['level2']['new_key']).to eq('value')
      end

      it 'returns BSON::Document at all nested levels' do
        result
        expect(document['level1']).to be_a(described_class)
        expect(document['level1']['level2']).to be_a(described_class)
        expect(document['level1']['level2']['level3']).to be_a(described_class)
      end
    end

    context 'when merging with arrays' do
      let(:document) do
        described_class.new(
          'key1' => 'value1',
          'array' => [1, 2, 3],
          'nested' => described_class.new(
            'array' => [4, 5, 6]
          )
        )
      end

      let(:other) do
        {
          'key2' => 'value2',
          'array' => [7, 8, 9],
          'nested' => {
            'array' => [10, 11, 12]
          }
        }
      end

      let(:result) do
        document.deep_merge!(other)
      end

      it 'replaces arrays instead of merging them' do
        result
        expect(document['array']).to eq([7, 8, 9])
        expect(document['nested']['array']).to eq([10, 11, 12])
      end
    end

    context 'when merging with non-hash values' do
      let(:document) do
        described_class.new(
          'key1' => 'value1',
          'key2' => described_class.new('inner' => 'value')
        )
      end

      let(:other) do
        {
          'key1' => 'new_value',
          'key2' => 'not_a_hash'
        }
      end

      let(:result) do
        document.deep_merge!(other)
      end

      it 'overwrites non-hash values' do
        result
        expect(document['key1']).to eq('new_value')
        expect(document['key2']).to eq('not_a_hash')
      end
    end

    context 'when a block is provided' do
      let(:document) do
        described_class.new(
          'key1' => 'value1',
          'nested' => described_class.new(
            'inner' => 5
          )
        )
      end

      let(:other) do
        {
          'key1' => 'new_value',
          'nested' => {
            'inner' => 10
          }
        }
      end

      let(:result) do
        document.deep_merge!(other) do |key, old_value, new_value|
          if key == 'inner' && old_value.is_a?(Integer) && new_value.is_a?(Integer)
            old_value + new_value
          else
            new_value
          end
        end
      end

      it 'applies the block to resolve conflicts' do
        result
        expect(document['key1']).to eq('new_value')
        expect(document['nested']['inner']).to eq(15) # 5 + 10
      end
    end

    context 'when merging with nil values' do
      let(:document) do
        described_class.new(
          'key1' => 'value1',
          'key2' => 'value2'
        )
      end

      let(:other) do
        {
          'key1' => nil,
          'key3' => nil
        }
      end

      let(:result) do
        document.deep_merge!(other)
      end

      it 'overwrites existing values with nil' do
        result
        expect(document['key1']).to be_nil
      end

      it 'adds new keys with nil values' do
        result
        expect(document.key?('key3')).to be true
        expect(document['key3']).to be_nil
      end
    end

    context 'when merging with deeply nested identical structures' do
      let(:document) do
        described_class.new(
          'config' => described_class.new(
            'options' => described_class.new(
              'timeout' => 30,
              'retry' => true
            )
          )
        )
      end

      let(:other) do
        {
          'config' => {
            'options' => {
              'timeout' => 60
            }
          }
        }
      end

      let(:result) do
        document.deep_merge!(other)
      end

      it 'preserves unmodified nested values' do
        result
        expect(document['config']['options']['retry']).to be true
      end

      it 'updates modified nested values' do
        result
        expect(document['config']['options']['timeout']).to eq(60)
      end

      it 'maintains the BSON::Document class throughout the structure' do
        result
        expect(document['config']).to be_a(described_class)
        expect(document['config']['options']).to be_a(described_class)
      end
    end

    context 'when the type of a nested structure changes' do
      let(:document) do
        described_class.new(
          'key' => described_class.new(
            'was_hash' => true
          )
        )
      end

      let(:other) do
        {
          'key' => 'now a string'
        }
      end

      let(:result) do
        document.deep_merge!(other)
      end

      it 'replaces the nested structure with the new type' do
        result
        expect(document['key']).to eq('now a string')
      end
    end
  end
end
