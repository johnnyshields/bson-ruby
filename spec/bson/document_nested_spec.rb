# rubocop:todo all

# Copyright (C) 2009-2020 MongoDB Inc.
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

describe BSON::Document do

  describe '.try_convert' do
    context 'when the object is convertible to a hash' do
      let(:hash) do
        { 'key' => 'value' }
      end

      it 'converts the object to a document' do
        doc = BSON::Document.try_convert(hash)
        expect(doc).to be_a(BSON::Document)
        expect(doc).to eq(BSON::Document.new('key' => 'value'))
      end
    end

    context 'when the object is contains a nested hash' do
      let(:hash) do
        { 'key1' => 'value1', 'nested' => { 'key2' => 'value2' } }
      end

      it 'returns a document' do
        expect(BSON::Document.try_convert(hash)).to be_a(BSON::Document)
      end

      it 'converts the nested hash to a document' do
        nested = BSON::Document.try_convert(hash)['nested']
        expect(nested).to be_a(BSON::Document)
        expect(nested).to eq(BSON::Document.new('key2' => 'value2'))
      end
    end

    context 'when the object is not convertible to a hash' do
      it 'returns nil' do
        expect(BSON::Document.try_convert('not a hash')).to be_nil
      end
    end
  end

  describe '.[]' do
    context 'with key-value pairs' do
      let(:document) do
        BSON::Document['key1', 'value1', 'key2', 'value2']
      end

      it 'creates a document with the provided keys and values' do
        expect(document).to be_a(BSON::Document)
        expect(document).to eq(BSON::Document.new('key1' => 'value1', 'key2' => 'value2'))
      end
    end

    context 'with a hash-like object' do
      let(:hash) do
        { 'key' => 'value' }
      end

      let(:document) do
        BSON::Document[hash]
      end

      it 'creates a document from the hash-like object' do
        expect(document).to be_a(BSON::Document)
        expect(document).to eq(BSON::Document.new('key' => 'value'))
      end
    end
  end

  describe '#to_h' do
    context 'with a single-level document' do
      let(:document) do
        BSON::Document.new('key1' => 'value1', 'key2' => 'value2')
      end

      let(:hash) do
        document.to_h
      end

      it 'returns a Hash' do
        expect(hash).to be_a(Hash)
      end

      it 'returns a hash with the same keys and values' do
        expect(hash).to eq({ 'key1' => 'value1', 'key2' => 'value2' })
      end
    end

    context 'with a nested document' do
      let(:document) do
        BSON::Document.new('key1' => 'value1', 'key2' => BSON::Document.new('key3' => 'value3'))
      end

      let(:hash) do
        document.to_h
      end

      it 'returns a Hash' do
        expect(hash).to be_a(Hash)
      end

      it 'converts nested documents to hashes' do
        expect(hash['key2']).to be_a(Hash)
      end

      it 'preserves the nested structure' do
        expect(hash).to eq({ 'key1' => 'value1', 'key2' => { 'key3' => 'value3' } })
      end
    end

    context 'when a block is provided' do
      let(:document) do
        BSON::Document.new('key1' => 'value1', 'key2' => 'value2')
      end

      let(:hash) do
        document.to_h { |k, v| [k.to_sym, v.upcase] }
      end

      it 'applies the block to each key-value pair' do
        expect(hash).to eq({ key1: 'VALUE1', key2: 'VALUE2' })
      end
    end
  end

  describe '#to_hash' do
    let(:document) do
      BSON::Document.new('key1' => 'value1', 'key2' => 'value2')
    end

    it 'is an alias for #to_h' do
      expect(document.method(:to_hash)).to eq(document.method(:to_h))
    end

    let(:hash) do
      document.to_hash
    end

    it 'returns a hash with the same keys and values' do
      expect(hash).to be_a(Hash)
      expect(hash).to eq({ 'key1' => 'value1', 'key2' => 'value2' })
    end
  end

  describe '#invert' do
    let(:document) do
      BSON::Document.new('key1' => 'value1', 'key2' => 'value2')
    end

    let(:inverted) do
      document.invert
    end

    it 'returns a BSON::Document' do
      expect(inverted).to be_a(BSON::Document)
    end

    it 'inverts keys and values' do
      expect(inverted).to eq(BSON::Document.new('value1' => 'key1', 'value2' => 'key2'))
    end

    context 'with nested documents' do
      let(:document) do
        BSON::Document.new('key1' => 'value1', 'key2' => BSON::Document.new('nested' => 'value2'))
      end

      let(:inverted) do
        document.invert
      end

      let(:nested_key) do
        inverted.keys.detect { |k| k.include?('nested') }
      end

      it 'does convert nested documents' do
        expect(nested_key).to be_a(BSON::Document)
      end

      it 'does not attempt to invert nested documents recursively' do
        expect(inverted[nested_key]).to eq('key2')
      end
    end
  end

  describe '#rehash' do
    let(:document) do
      BSON::Document.new('key1' => 'value1', 'key2' => 'value2')
    end

    it 'returns self' do
      expect(document.rehash).to be(document)
    end

    context 'with mutable keys' do
      let(:mutable_key) do
        { id: 1 }
      end

      let(:document) do
        BSON::Document.new(mutable_key => 'value')
      end

      before do
        mutable_key[:id] = 2
      end

      it 'rebuilds hash index after key changes' do
        expect { document.rehash }.not_to raise_error
        expect(document.keys.first).to eq({ id: 2 })
      end
    end
  end

  describe '#delete' do
    let(:document) do
      BSON::Document.new('key1' => 'value1', 'key2' => 'value2')
    end

    context 'when the key exists' do
      it 'returns the value' do
        expect(document.delete('key1')).to eq('value1')
      end

      it 'removes the key-value pair' do
        document.delete('key1')
        expect(document).to eq(BSON::Document.new('key2' => 'value2'))
      end
    end

    context 'when the key is a symbol' do
      let(:document) do
        BSON::Document.new(key1: 'value1', 'key2' => 'value2')
      end

      it 'returns the value' do
        expect(document.delete(:key1)).to eq('value1')
      end

      it 'removes the key-value pair' do
        document.delete(:key1)
        expect(document).to eq(BSON::Document.new('key2' => 'value2'))
      end
    end

    context 'when the key does not exist' do
      it 'returns nil' do
        expect(document.delete('nonexistent')).to be_nil
      end
    end

    context 'when a block is provided' do
      let(:value) do
        document.delete('key1') { |key| "default for #{key}" }
      end

      it 'returns the result of the block' do
        expect(value).to eq('value1')
      end
    end

    context 'when a block is provided and the key does not exist' do
      let(:value) do
        document.delete('nonexistent') { |key| "default for #{key}" }
      end

      it 'returns the result of the block' do
        expect(value).to eq('default for nonexistent')
      end
    end
  end

  describe '#delete_if' do
    let(:document) do
      BSON::Document.new('key1' => 'value1', 'key2' => 'value2', 'key3' => 'value3')
    end

    let(:result) do
      document.delete_if { |k, v| k == 'key1' || v == 'value3' }
    end

    it 'returns self' do
      expect(result).to be(document)
    end

    it 'removes keys for which the block returns true' do
      result
      expect(document).to eq(BSON::Document.new('key2' => 'value2'))
    end

    context 'when no block is given' do
      it 'returns an enumerator' do
        expect(document.delete_if).to be_a(Enumerator)
      end
    end
  end

  describe '#clear' do
    let(:document) do
      BSON::Document.new('key1' => 'value1', 'key2' => 'value2')
    end

    let(:result) do
      document.clear
    end

    it 'returns self' do
      expect(result).to be(document)
    end

    it 'removes all key-value pairs' do
      result
      expect(document).to be_empty
    end
  end

  describe '#shift' do
    let(:document) do
      BSON::Document.new('key1' => 'value1', 'key2' => 'value2')
    end

    let(:pair) do
      document.shift
    end

    it 'returns the first key-value pair as an array' do
      expect(pair).to eq(['key1', 'value1'])
    end

    it 'removes the first key-value pair' do
      document.shift
      expect(document).to eq(BSON::Document.new('key2' => 'value2'))
    end

    context 'when the document is empty' do
      let(:empty_document) do
        BSON::Document.new
      end

      it 'returns nil' do
        expect(empty_document.shift).to be_nil
      end
    end
  end

  describe '#merge' do
    let(:document) do
      BSON::Document.new('key1' => 'value1', 'key2' => 'value2')
    end

    context 'when merging with another document' do
      let(:other) do
        BSON::Document.new('key2' => 'new_value', 'key3' => 'value3')
      end

      let(:result) do
        document.merge(other)
      end

      it 'returns a BSON::Document' do
        expect(result).to be_a(BSON::Document)
      end

      it 'is not the same object as the original' do
        expect(result).not_to be(document)
      end

      it 'includes all keys from both documents' do
        expect(result.keys).to include('key1', 'key2', 'key3')
      end

      it 'uses values from the other document for duplicate keys' do
        expect(result['key2']).to eq('new_value')
      end
    end

    context 'when merging with a hash' do
      let(:other) do
        { 'key2' => 'new_value', 'key3' => 'value3' }
      end

      let(:result) do
        document.merge(other)
      end

      it 'returns a BSON::Document' do
        expect(result).to be_a(BSON::Document)
      end

      it 'includes all keys from both documents' do
        expect(result.keys).to include('key1', 'key2', 'key3')
      end
    end

    context 'when a block is provided' do
      let(:other) do
        { 'key1' => 'other_value', 'key3' => 'value3' }
      end

      let(:result) do
        document.merge(other) do |_key, old_val, new_val|
          "#{old_val} and #{new_val}"
        end
      end

      it 'uses the result of the block for duplicate keys' do
        expect(result['key1']).to eq('value1 and other_value')
      end

      it 'uses the value of the other hash for non-duplicate keys' do
        expect(result['key3']).to eq('value3')
      end
    end

    context 'with nested documents' do
      let(:document) do
        BSON::Document.new('key1' => 'value1', 'nested' => BSON::Document.new('a' => 1, 'b' => 2))
      end

      let(:other) do
        { 'key2' => 'value2', 'nested' => { 'b' => 3, 'c' => 4 } }
      end

      let(:result) do
        document.merge(other)
      end

      it 'replaces the nested document' do
        expect(result['nested']).to eq(BSON::Document.new('b' => 3, 'c' => 4))
      end

      it 'returns nested BSON::Documents' do
        expect(result['nested']).to be_a(BSON::Document)
      end
    end
  end

  describe '#merge!' do
    let(:document) do
      BSON::Document.new('key1' => 'value1', 'key2' => 'value2')
    end

    context 'when merging with another document' do
      let(:other) do
        BSON::Document.new('key2' => 'new_value', 'key3' => 'value3')
      end

      let(:result) do
        document.merge!(other)
      end

      it 'returns self' do
        expect(result).to be(document)
      end

      it 'modifies the original document' do
        result
        expect(document['key2']).to eq('new_value')
        expect(document['key3']).to eq('value3')
      end
    end

    context 'when merging with a hash' do
      let(:other) do
        { 'key2' => 'new_value', 'key3' => 'value3' }
      end

      let(:result) do
        document.merge!(other)
      end

      it 'returns self' do
        expect(result).to be(document)
      end

      it 'modifies the original document' do
        result
        expect(document['key2']).to eq('new_value')
        expect(document['key3']).to eq('value3')
      end
    end

    context 'when a block is provided' do
      let(:other) do
        { 'key1' => 'other_value', 'key3' => 'value3' }
      end

      let(:result) do
        document.merge!(other) do |_key, old_val, new_val|
          "#{old_val} and #{new_val}"
        end
      end

      it 'uses the result of the block for duplicate keys' do
        result
        expect(document['key1']).to eq('value1 and other_value')
      end

      it 'uses the value of the other hash for non-duplicate keys' do
        result
        expect(document['key3']).to eq('value3')
      end
    end

    context 'with nested documents' do
      let(:document) do
        BSON::Document.new('key1' => 'value1', 'nested' => BSON::Document.new('a' => 1, 'b' => 2))
      end

      let(:other) do
        { 'key2' => 'value2', 'nested' => { 'b' => 3, 'c' => 4 } }
      end

      let(:result) do
        document.merge!(other)
      end

      it 'replaces the nested document' do
        result
        expect(document['nested']).to eq(BSON::Document.new('b' => 3, 'c' => 4))
      end

      it 'converts the nested hash to a BSON::Document' do
        result
        expect(document['nested']).to be_a(BSON::Document)
      end
    end
  end

  describe '#update' do
    let(:document) do
      BSON::Document.new('key1' => 'value1')
    end

    let(:other) do
      { 'key2' => 'value2' }
    end

    it 'is an alias for merge!' do
      expect(document.method(:update)).to eq(document.method(:merge!))
    end

    it 'updates the document in place' do
      document.update(other)
      expect(document).to eq(BSON::Document.new('key1' => 'value1', 'key2' => 'value2'))
    end
  end

  describe '#reject' do
    let(:document) do
      BSON::Document.new('key1' => 'value1', 'key2' => 'value2', 'key3' => 'value3')
    end

    let(:result) do
      document.reject { |k, v| k == 'key1' || v == 'value3' }
    end

    it 'returns a new BSON::Document' do
      expect(result).to be_a(BSON::Document)
      expect(result).not_to be(document)
    end

    it 'excludes keys for which the block returns true' do
      expect(result).to eq(BSON::Document.new('key2' => 'value2'))
    end

    it 'does not modify the original document' do
      result
      expect(document).to eq(BSON::Document.new('key1' => 'value1', 'key2' => 'value2', 'key3' => 'value3'))
    end

    context 'when no block is given' do
      it 'returns an enumerator' do
        expect(document.reject).to be_a(Enumerator)
      end
    end
  end

  describe '#reject!' do
    let(:document) do
      BSON::Document.new('key1' => 'value1', 'key2' => 'value2', 'key3' => 'value3')
    end

    context 'when changes are made' do
      let(:result) do
        document.reject! { |k, v| k == 'key1' || v == 'value3' }
      end

      it 'returns self' do
        expect(result).to be(document)
      end

      it 'modifies the original document' do
        result
        expect(document).to eq(BSON::Document.new('key2' => 'value2'))
      end
    end

    context 'when no changes are made' do
      let(:result) do
        document.reject! { |k, v| false }
      end

      it 'returns nil' do
        expect(result).to be_nil
      end

      it 'does not modify the original document' do
        result
        expect(document).to eq(BSON::Document.new('key1' => 'value1', 'key2' => 'value2', 'key3' => 'value3'))
      end
    end

    context 'when no block is given' do
      it 'returns an enumerator' do
        expect(document.reject!).to be_a(Enumerator)
      end
    end
  end

  describe '#select' do
    let(:document) do
      BSON::Document.new('key1' => 'value1', 'key2' => 'value2', 'key3' => 'value3')
    end

    let(:result) do
      document.select { |k, v| k == 'key1' || v == 'value3' }
    end

    it 'returns a new BSON::Document' do
      expect(result).to be_a(BSON::Document)
      expect(result).not_to be(document)
    end

    it 'includes keys for which the block returns true' do
      expect(result).to eq(BSON::Document.new('key1' => 'value1', 'key3' => 'value3'))
    end

    it 'does not modify the original document' do
      result
      expect(document).to eq(BSON::Document.new('key1' => 'value1', 'key2' => 'value2', 'key3' => 'value3'))
    end

    context 'when no block is given' do
      it 'returns an enumerator' do
        expect(document.select).to be_a(Enumerator)
      end
    end
  end

  describe '#select!' do
    let(:document) do
      BSON::Document.new('key1' => 'value1', 'key2' => 'value2', 'key3' => 'value3')
    end

    context 'when changes are made' do
      let(:result) do
        document.select! { |k, v| k == 'key1' || v == 'value3' }
      end

      it 'returns self' do
        expect(result).to be(document)
      end

      it 'modifies the original document' do
        result
        expect(document).to eq(BSON::Document.new('key1' => 'value1', 'key3' => 'value3'))
      end
    end

    context 'when no changes are made' do
      let(:result) do
        document.select! { |k, v| true }
      end

      it 'returns nil' do
        expect(result).to be_nil
      end

      it 'does not modify the original document' do
        result
        expect(document).to eq(BSON::Document.new('key1' => 'value1', 'key2' => 'value2', 'key3' => 'value3'))
      end
    end

    context 'when no block is given' do
      it 'returns an enumerator' do
        expect(document.select!).to be_a(Enumerator)
      end
    end
  end

  describe '#filter' do
    let(:document) do
      BSON::Document.new('key1' => 'value1', 'key2' => 'value2')
    end

    it 'is an alias for select' do
      expect(document.method(:filter)).to eq(document.method(:select))
    end
  end

  describe '#filter!' do
    let(:document) do
      BSON::Document.new('key1' => 'value1', 'key2' => 'value2')
    end

    it 'is an alias for select!' do
      expect(document.method(:filter!)).to eq(document.method(:select!))
    end
  end

  describe '#keep_if' do
    let(:document) do
      BSON::Document.new('key1' => 'value1', 'key2' => 'value2', 'key3' => 'value3')
    end

    let(:result) do
      document.keep_if { |k, v| k == 'key1' || v == 'value3' }
    end

    it 'returns self' do
      expect(result).to be(document)
    end

    it 'modifies the original document' do
      result
      expect(document).to eq(BSON::Document.new('key1' => 'value1', 'key3' => 'value3'))
    end

    context 'when no block is given' do
      it 'returns an enumerator' do
        expect(document.keep_if).to be_a(Enumerator)
      end
    end
  end

  describe '#compact' do
    let(:document) do
      BSON::Document.new('key1' => 'value1', 'key2' => nil, 'key3' => 'value3')
    end

    let(:result) do
      document.compact
    end

    it 'returns a new BSON::Document' do
      expect(result).to be_a(BSON::Document)
      expect(result).not_to be(document)
    end

    it 'excludes pairs with nil values' do
      expect(result).to eq(BSON::Document.new('key1' => 'value1', 'key3' => 'value3'))
    end

    it 'does not modify the original document' do
      result
      expect(document).to eq(BSON::Document.new('key1' => 'value1', 'key2' => nil, 'key3' => 'value3'))
    end
  end

  describe '#compact!' do
    let(:document) do
      BSON::Document.new('key1' => 'value1', 'key2' => nil, 'key3' => 'value3')
    end

    context 'when there are nil values' do
      let(:result) do
        document.compact!
      end

      it 'returns self' do
        expect(result).to be(document)
      end

      it 'modifies the original document' do
        result
        expect(document).to eq(BSON::Document.new('key1' => 'value1', 'key3' => 'value3'))
      end
    end

    context 'when there are no nil values' do
      let(:document) do
        BSON::Document.new('key1' => 'value1', 'key3' => 'value3')
      end

      let(:result) do
        document.compact!
      end

      it 'returns nil' do
        expect(result).to be_nil
      end

      it 'does not modify the original document' do
        result
        expect(document).to eq(BSON::Document.new('key1' => 'value1', 'key3' => 'value3'))
      end
    end
  end

  describe '#slice' do
    context 'with a single-level document' do
      let(:document) do
        BSON::Document.new('key1' => 'value1', 'key2' => 'value2', 'key3' => 'value3')
      end

      let(:result) do
        document.slice('key1', 'key3')
      end

      it 'returns a new BSON::Document' do
        expect(result).to be_a(BSON::Document)
        expect(result).not_to be(document)
      end

      it 'includes only the specified keys' do
        expect(result).to eq(BSON::Document.new('key1' => 'value1', 'key3' => 'value3'))
      end

      it 'does not modify the original document' do
        result
        expect(document).to eq(BSON::Document.new('key1' => 'value1', 'key2' => 'value2', 'key3' => 'value3'))
      end
    end

    context 'when some keys do not exist' do
      let(:document) do
        BSON::Document.new('key1' => 'value1', 'key2' => 'value2')
      end

      let(:result) do
        document.slice('key1', 'nonexistent')
      end

      it 'includes only the existing keys' do
        expect(result).to eq(BSON::Document.new('key1' => 'value1'))
      end
    end

    context 'with symbol keys' do
      let(:document) do
        BSON::Document.new(key1: 'value1', key2: 'value2')
      end

      let(:result) do
        document.slice(:key1)
      end

      it 'handles symbol keys correctly' do
        expect(result).to eq(BSON::Document.new('key1' => 'value1'))
      end
    end
  end

  describe '#transform_keys' do
    let(:document) do
      BSON::Document.new('key1' => 'value1', 'key2' => 'value2')
    end

    let(:result) do
      document.transform_keys { |key| key.upcase }
    end

    it 'returns a Hash, not a BSON::Document' do
      expect(result).to be_a(Hash)
      expect(result).not_to be_a(BSON::Document)
    end

    it 'transforms all keys according to the block' do
      expect(result).to eq({ 'KEY1' => 'value1', 'KEY2' => 'value2' })
    end

    it 'does not modify the original document' do
      result
      expect(document).to eq(BSON::Document.new('key1' => 'value1', 'key2' => 'value2'))
    end

    context 'with nested documents' do
      let(:document) do
        BSON::Document.new('outer' => BSON::Document.new('inner' => 'value'))
      end

      let(:result) do
        document.transform_keys { |key| key.upcase }
      end

      it 'does not transform keys in nested documents' do
        expect(result).to eq({ 'OUTER' => { 'inner' => 'value' } })
      end

      it 'converts nested BSON::Documents to plain Hashes' do
        expect(result['OUTER']).to be_a(Hash)
        expect(result['OUTER']).not_to be_a(BSON::Document)
      end
    end
  end

  describe '#transform_keys!' do
    context 'with a simple document' do
      let(:document) do
        BSON::Document.new('key1' => 'value1', 'key2' => 'value2')
      end

      let(:result) do
        document.transform_keys! { |key| key.upcase }
      end

      it 'returns self' do
        expect(result).to be(document)
      end

      it 'transforms all keys according to the block' do
        result
        expect(document.keys).to eq(['KEY1', 'KEY2'])
      end
    end

    context 'with nested documents' do
      let(:document) do
        BSON::Document.new('outer' => BSON::Document.new('inner' => 'value'))
      end

      let(:result) do
        document.transform_keys! { |key| key.upcase }
      end

      it 'does not transform keys in nested documents' do
        result
        expect(document['OUTER'].keys).to eq(['inner'])
      end

      it 'preserves nested BSON::Documents' do
        result
        expect(document['OUTER']).to be_a(BSON::Document)
      end
    end
  end

  describe '#transform_values' do
    let(:document) do
      BSON::Document.new('key1' => 'value1', 'key2' => 'value2')
    end

    let(:result) do
      document.transform_values { |value| value.upcase }
    end

    it 'returns a Hash, not a BSON::Document' do
      expect(result).to be_a(Hash)
      expect(result).not_to be_a(BSON::Document)
    end

    it 'transforms all values according to the block' do
      expect(result).to eq({ 'key1' => 'VALUE1', 'key2' => 'VALUE2' })
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
        document.transform_values { |value| value.is_a?(BSON::Document) ? 'transformed' : value }
      end

      it 'allows transforming nested documents' do
        expect(result).to eq({ 'key1' => 'transformed' })
      end
    end
  end

  describe '#transform_values!' do
    let(:document) do
      BSON::Document.new('key1' => 'value1', 'key2' => 'value2')
    end

    let(:result) do
      document.transform_values! { |value| value.upcase }
    end

    it 'returns self' do
      expect(result).to be(document)
    end

    it 'transforms all values according to the block' do
      result
      expect(document).to eq(BSON::Document.new('key1' => 'VALUE1', 'key2' => 'VALUE2'))
    end

    context 'with nested documents' do
      let(:document) do
        BSON::Document.new('key1' => BSON::Document.new('inner' => 'value'))
      end

      let(:result) do
        document.transform_values! { |value| value.is_a?(BSON::Document) ? 'transformed' : value }
      end

      it 'allows transforming nested documents' do
        result
        expect(document).to eq(BSON::Document.new('key1' => 'transformed'))
      end
    end
  end
end
