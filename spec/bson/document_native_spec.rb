# frozen_string_literal: true
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

# BSON::Document tests for native Hash method behaviors
describe BSON::Document do

  describe '.try_convert' do
    let(:object) do
      { 'key1' => 'value1' }
    end

    let(:document) do
      described_class.try_convert(object)
    end

    it 'converts the object to a document' do
      expect(document).to be_a(described_class)
      expect(document).to eq(described_class.new('key1' => 'value1'))
    end

    context 'when the object is contains a nested hash' do
      let(:object) do
        { 'key1' => 'value1', 'nested' => { 'key2' => 'value2' } }
      end

      it 'converts the nested hash to a document' do
        nested = document['nested']
        expect(nested).to be_a(described_class)
        expect(nested).to eq(described_class.new('key2' => 'value2'))
      end
    end

    context 'when the object is a BSON::Document' do
      let(:object) do
        described_class.new('key1' => 'value1')
      end

      it 'returns the document itself self' do
        expect(document).to eq(object)
      end
    end

    context 'when the object is not convertible to a hash' do
      let(:object) do
        'not a hash'
      end

      it 'returns nil' do
        expect(document).to be_nil
      end
    end
  end

  describe '.[]' do
    context 'with key-value pairs' do
      let(:document) do
        described_class['key1', 'value1', 'key2', 'value2']
      end

      it 'creates a document with the provided keys and values' do
        expect(document).to be_a(described_class)
        expect(document).to eq(described_class.new('key1' => 'value1', 'key2' => 'value2'))
      end
    end

    context 'with a hash-like object' do
      let(:hash) do
        { 'key' => 'value' }
      end

      let(:document) do
        described_class[hash]
      end

      it 'creates a document from the hash-like object' do
        expect(document).to be_a(described_class)
        expect(document).to eq(described_class.new('key' => 'value'))
      end
    end
  end

  describe '#to_h' do
    context 'with a single-level document' do
      let(:document) do
        described_class.new('key1' => 'value1', 'key2' => 'value2')
      end

      let(:hash) do
        document.to_h
      end

      it 'returns a Hash' do
        expect(hash).to be_a(Hash)
        expect(hash).to_not be_a(described_class)
      end

      it 'returns a hash with the same keys and values' do
        expect(hash).to eq({ 'key1' => 'value1', 'key2' => 'value2' })
      end
    end

    context 'with a nested document' do
      let(:document) do
        described_class.new('key1' => 'value1', 'key2' => described_class.new('key3' => 'value3'))
      end

      let(:hash) do
        document.to_h
      end

      it 'converts nested documents to hashes' do
        nested = hash['key2']
        expect(nested).to be_a(Hash)
        expect(nested).to_not be_a(described_class)
      end

      it 'preserves the nested structure' do
        expect(hash).to eq({ 'key1' => 'value1', 'key2' => { 'key3' => 'value3' } })
      end
    end

    context 'when a block is provided' do
      let(:document) do
        described_class.new('key1' => 'value1', 'key2' => 'value2')
      end

      let(:hash) do
        document.to_h { |k, v| [k.to_sym, v.upcase] }
      end

      it 'returns a Hash' do
        expect(hash).to be_a(Hash)
        expect(hash).to_not be_a(described_class)
      end

      it 'applies the block to each key-value pair' do
        expect(hash).to eq({ key1: 'VALUE1', key2: 'VALUE2' })
      end
    end
  end

  describe '#to_hash' do
    let(:document) do
      described_class.new('key1' => 'value1', 'key2' => 'value2')
    end

    it 'is an alias for #to_h' do
      expect(document.method(:to_hash)).to eq(document.method(:to_h))
    end

    let(:hash) do
      document.to_hash
    end

    it 'returns a hash with the same keys and values' do
      expect(hash).to be_a(Hash)
      expect(hash).to_not be_a(described_class)
      expect(hash).to eq({ 'key1' => 'value1', 'key2' => 'value2' })
    end
  end

  describe '#invert' do
    let(:document) do
      described_class.new('key1' => 'value1', 'key2' => 'value2')
    end

    let(:inverted) do
      document.invert
    end

    it 'returns a new BSON::Document' do
      expect(inverted).to be_a(described_class)
      expect(inverted).not_to be(document)
    end

    it 'inverts keys and values' do
      expect(inverted).to eq(described_class.new('value1' => 'key1', 'value2' => 'key2'))
    end

    context 'with nested documents' do
      let(:document) do
        described_class.new('key1' => 'value1', 'key2' => described_class.new('nested' => 'value2'))
      end

      let(:inverted) do
        document.invert
      end

      let(:nested_key) do
        inverted.keys.detect { |k| k.include?('nested') }
      end

      it 'does convert nested documents' do
        expect(nested_key).to be_a(described_class)
        expect(nested_key).to eq(document['key2'])
      end

      it 'does not attempt to invert nested documents recursively' do
        expect(inverted[nested_key]).to eq('key2')
      end
    end
  end

  describe '#rehash' do
    let(:document) do
      described_class.new('key1' => 'value1', 'key2' => 'value2')
    end

    it 'returns self' do
      expect(document.rehash).to be(document)
    end

    context 'with mutable keys' do
      let(:mutable_key) do
        { id: 1 }
      end

      let(:document) do
        described_class.new(mutable_key => 'value')
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
      described_class.new('key1' => 'value1', 'key2' => 'value2')
    end

    context 'when the key exists' do
      it 'returns the value' do
        expect(document.delete('key1')).to eq('value1')
      end

      it 'removes the key-value pair' do
        document.delete('key1')
        expect(document).to eq(described_class.new('key2' => 'value2'))
      end
    end

    context 'when the key is a symbol' do
      let(:document) do
        described_class.new(key1: 'value1', 'key2' => 'value2')
      end

      it 'returns the value' do
        expect(document.delete(:key1)).to eq('value1')
      end

      it 'removes the key-value pair' do
        document.delete(:key1)
        expect(document).to eq(described_class.new('key2' => 'value2'))
      end
    end

    context 'when the key does not exist' do
      it 'returns nil' do
        expect(document.delete('nonexistent')).to be_nil
      end
    end

    context 'when a block is provided' do
      let(:value) do
        document.delete('key1') { |key| 'default for #{key}' }
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
      described_class.new('key1' => 'value1', 'key2' => 'value2', 'key3' => 'value3')
    end

    let(:result) do
      document.delete_if { |k, v| k == 'key1' || v == 'value3' }
    end

    it 'returns self' do
      expect(result).to be(document)
    end

    it 'removes keys for which the block returns true' do
      result
      expect(document).to eq(described_class.new('key2' => 'value2'))
    end

    context 'when block not given' do
      let(:enumerator) do
        document.dup.delete_if
      end

      it 'returns an enumerator' do
        expect(enumerator).to be_a(Enumerator)
      end

      it 'enumerates over all key-value pairs' do
        pairs = enumerator.to_a
        expect(pairs.length).to eq(document.length)
        expect(pairs.map(&:first)).to eq(document.keys)
        expect(pairs.map(&:last)).to eq(document.values)
      end

      it 'modifies the original document when used with a block' do
        doc_copy = document.dup
        result = doc_copy.delete_if.each { |key, value| key == 'key1' || value == 'value3' }
        expect(result).to be(doc_copy)
        expect(doc_copy).to eq(described_class.new('key2' => 'value2'))
      end
    end
  end

  describe '#clear' do
    let(:document) do
      described_class.new('key1' => 'value1', 'key2' => 'value2')
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
      described_class.new('key1' => 'value1', 'key2' => 'value2')
    end

    let(:pair) do
      document.shift
    end

    it 'returns the first key-value pair as an array' do
      expect(pair).to eq(%w[key1 value1])
    end

    it 'removes the first key-value pair from the document' do
      document.shift
      expect(document).to eq(described_class.new('key2' => 'value2'))
    end

    context 'when the document is empty' do
      let(:empty_document) do
        described_class.new
      end

      it 'returns nil' do
        expect(empty_document.shift).to be_nil
      end
    end
  end

  describe '#merge' do
    let(:document) do
      described_class.new('key1' => 'value1', 'key2' => 'value2')
    end

    context 'when merging with another document' do
      let(:other) do
        described_class.new('key2' => 'new_value', 'key3' => 'value3')
      end

      let(:result) do
        document.merge(other)
      end

      it 'returns a new BSON::Document' do
        expect(result).to be_a(described_class)
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
        expect(result).to be_a(described_class)
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
        described_class.new('key1' => 'value1', 'nested' => described_class.new('a' => 1, 'b' => 2))
      end

      let(:other) do
        { 'key2' => 'value2', 'nested' => { 'b' => 3, 'c' => 4 } }
      end

      let(:result) do
        document.merge(other)
      end

      it 'replaces the nested document' do
        expect(result['nested']).to eq(described_class.new('b' => 3, 'c' => 4))
      end

      it 'returns nested BSON::Document' do
        expect(result['nested']).to be_a(described_class)
      end
    end
  end

  describe '#merge!' do
    let(:document) do
      described_class.new('key1' => 'value1', 'key2' => 'value2')
    end

    context 'when merging with another document' do
      let(:other) do
        described_class.new('key2' => 'new_value', 'key3' => 'value3')
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
        described_class.new('key1' => 'value1', 'nested' => described_class.new('a' => 1, 'b' => 2))
      end

      let(:other) do
        { 'key2' => 'value2', 'nested' => { 'b' => 3, 'c' => 4 } }
      end

      let(:result) do
        document.merge!(other)
      end

      it 'replaces the nested document' do
        result
        expect(document['nested']).to eq(described_class.new('b' => 3, 'c' => 4))
      end

      it 'converts the nested hash to a BSON::Document' do
        result
        expect(document['nested']).to be_a(described_class)
      end
    end
  end

  describe '#update' do
    let(:document) do
      described_class.new('key1' => 'value1')
    end

    let(:other) do
      { 'key2' => 'value2' }
    end

    it 'is an alias for merge!' do
      expect(document.method(:update)).to eq(document.method(:merge!))
    end

    it 'updates the document in place' do
      document.update(other)
      expect(document).to eq(described_class.new('key1' => 'value1', 'key2' => 'value2'))
    end
  end

  describe '#reject' do
    let(:document) do
      described_class.new('key1' => 'value1', 'key2' => 'value2', 'key3' => 'value3')
    end

    let(:result) do
      document.reject { |k, v| k == 'key1' || v == 'value3' }
    end

    it 'returns a new BSON::Document' do
      expect(result).to be_a(described_class)
      expect(result).not_to be(document)
    end

    it 'excludes keys for which the block returns true' do
      expect(result).to eq(described_class.new('key2' => 'value2'))
    end

    it 'does not modify the original document' do
      result
      expect(document).to eq(described_class.new('key1' => 'value1', 'key2' => 'value2', 'key3' => 'value3'))
    end

    context 'when block not given' do
      let(:enumerator) do
        document.reject
      end

      it 'returns an enumerator' do
        expect(enumerator).to be_a(Enumerator)
      end

      it 'enumerates over all key-value pairs' do
        pairs = enumerator.to_a
        expect(pairs.length).to eq(document.length)
        expect(pairs.map(&:first)).to eq(document.keys)
        expect(pairs.map(&:last)).to eq(document.values)
      end

      it 'produces a BSON::Document when used with a block' do
        result = enumerator.each { |key, value| key == 'key1' || value == 'value3' }
        expect(result).to be_a(described_class)
        expect(result).to eq(described_class.new('key2' => 'value2'))
      end
    end
  end

  describe '#reject!' do
    let(:document) do
      described_class.new('key1' => 'value1', 'key2' => 'value2', 'key3' => 'value3')
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
        expect(document).to eq(described_class.new('key2' => 'value2'))
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
        expect(document).to eq(described_class.new('key1' => 'value1', 'key2' => 'value2', 'key3' => 'value3'))
      end
    end

    context 'when block not given' do
      let(:enumerator) do
        document.dup.reject!
      end

      it 'returns an enumerator' do
        expect(enumerator).to be_a(Enumerator)
      end

      it 'enumerates over all key-value pairs' do
        pairs = enumerator.to_a
        expect(pairs.length).to eq(document.length)
        expect(pairs.map(&:first)).to eq(document.keys)
        expect(pairs.map(&:last)).to eq(document.values)
      end

      it 'modifies the original document when used with a block' do
        doc_copy = document.dup
        result = doc_copy.reject!.each { |key, value| key == 'key1' || value == 'value3' }
        expect(result).to be(doc_copy)
        expect(doc_copy).to eq(described_class.new('key2' => 'value2'))
      end

      it 'returns nil if no changes are made' do
        doc_copy = document.dup
        result = doc_copy.reject!.each { |key, value| false }
        expect(result).to be_nil
        expect(doc_copy).to eq(document)
      end
    end
  end

  describe '#select' do
    let(:document) do
      described_class.new('key1' => 'value1', 'key2' => 'value2', 'key3' => 'value3')
    end

    let(:result) do
      document.select { |k, v| k == 'key1' || v == 'value3' }
    end

    it 'returns a new BSON::Document' do
      expect(result).to be_a(described_class)
      expect(result).not_to be(document)
    end

    it 'includes keys for which the block returns true' do
      expect(result).to eq(described_class.new('key1' => 'value1', 'key3' => 'value3'))
    end

    it 'does not modify the original document' do
      result
      expect(document).to eq(described_class.new('key1' => 'value1', 'key2' => 'value2', 'key3' => 'value3'))
    end

    context 'when block not given' do
      let(:enumerator) do
        document.select
      end

      it 'returns an enumerator' do
        expect(enumerator).to be_a(Enumerator)
      end

      it 'enumerates over all key-value pairs' do
        pairs = enumerator.to_a
        expect(pairs.length).to eq(document.length)
        expect(pairs.map(&:first)).to eq(document.keys)
        expect(pairs.map(&:last)).to eq(document.values)
      end

      it 'produces a BSON::Document when used with a block' do
        result = enumerator.each { |key, value| key == 'key1' || value == 'value3' }
        expect(result).to be_a(described_class)
        expect(result).to eq(described_class.new('key1' => 'value1', 'key3' => 'value3'))
      end
    end
  end

  describe '#select!' do
    let(:document) do
      described_class.new('key1' => 'value1', 'key2' => 'value2', 'key3' => 'value3')
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
        expect(document).to eq(described_class.new('key1' => 'value1', 'key3' => 'value3'))
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
        expect(document).to eq(described_class.new('key1' => 'value1', 'key2' => 'value2', 'key3' => 'value3'))
      end
    end

    context 'when block not given' do
      let(:enumerator) do
        document.dup.select!
      end

      it 'returns an enumerator' do
        expect(enumerator).to be_a(Enumerator)
      end

      it 'enumerates over all key-value pairs' do
        pairs = enumerator.to_a
        expect(pairs.length).to eq(document.length)
        expect(pairs.map(&:first)).to eq(document.keys)
        expect(pairs.map(&:last)).to eq(document.values)
      end

      it 'modifies the original document when used with a block' do
        doc_copy = document.dup
        result = doc_copy.select!.each { |key, value| key == 'key1' || value == 'value3' }
        expect(result).to be(doc_copy)
        expect(doc_copy).to eq(described_class.new('key1' => 'value1', 'key3' => 'value3'))
      end

      it 'returns nil if no changes are made' do
        doc_copy = document.dup
        result = doc_copy.select!.each { |key, value| true }
        expect(result).to be_nil
        expect(doc_copy).to eq(document)
      end
    end
  end

  describe '#filter' do
    let(:document) do
      described_class.new('key1' => 'value1', 'key2' => 'value2', 'key3' => 'value3')
    end

    it 'is an alias for select' do
      expect(document.method(:filter)).to eq(document.method(:select))
    end

    context 'when block not given' do
      let(:enumerator) do
        document.filter
      end

      it 'is an alias for select' do
        expect(document.method(:filter)).to eq(document.method(:select))
      end

      it 'returns an enumerator' do
        expect(enumerator).to be_a(Enumerator)
      end

      it 'produces a BSON::Document when used with a block' do
        result = enumerator.each { |key, value| key == 'key1' || value == 'value3' }
        expect(result).to be_a(described_class)
        expect(result).to eq(described_class.new('key1' => 'value1', 'key3' => 'value3'))
      end
    end
  end

  describe '#filter!' do
    let(:document) do
      described_class.new('key1' => 'value1', 'key2' => 'value2', 'key3' => 'value3')
    end

    it 'is an alias for select!' do
      expect(document.method(:filter!)).to eq(document.method(:select!))
    end

    context 'when block not given' do
      let(:enumerator) do
        document.dup.filter!
      end

      it 'is an alias for select!' do
        expect(document.method(:filter!)).to eq(document.method(:select!))
      end

      it 'returns an enumerator' do
        expect(enumerator).to be_a(Enumerator)
      end

      it 'modifies the original document when used with a block' do
        doc_copy = document.dup
        result = doc_copy.filter!.each { |key, value| key == 'key1' || value == 'value3' }
        expect(result).to be(doc_copy)
        expect(doc_copy).to eq(described_class.new('key1' => 'value1', 'key3' => 'value3'))
      end
    end
  end

  describe '#keep_if' do
    let(:document) do
      described_class.new('key1' => 'value1', 'key2' => 'value2', 'key3' => 'value3')
    end

    let(:result) do
      document.keep_if { |k, v| k == 'key1' || v == 'value3' }
    end

    it 'returns self' do
      expect(result).to be(document)
    end

    it 'modifies the original document' do
      result
      expect(document).to eq(described_class.new('key1' => 'value1', 'key3' => 'value3'))
    end

    context 'when block not given' do
      let(:enumerator) do
        document.dup.keep_if
      end

      it 'returns an enumerator' do
        expect(enumerator).to be_a(Enumerator)
      end

      it 'enumerates over all key-value pairs' do
        pairs = enumerator.to_a
        expect(pairs.length).to eq(document.length)
        expect(pairs.map(&:first)).to eq(document.keys)
        expect(pairs.map(&:last)).to eq(document.values)
      end

      it 'modifies the original document when used with a block' do
        doc_copy = document.dup
        result = doc_copy.keep_if.each { |key, value| key == 'key1' || value == 'value3' }
        expect(result).to be(doc_copy)
        expect(doc_copy).to eq(described_class.new('key1' => 'value1', 'key3' => 'value3'))
      end
    end
  end

  describe '#compact' do
    let(:document) do
      described_class.new('key1' => 'value1', 'key2' => nil, 'key3' => 'value3')
    end

    let(:result) do
      document.compact
    end

    it 'returns a new BSON::Document' do
      expect(result).to be_a(described_class)
      expect(result).not_to be(document)
    end

    it 'excludes pairs with nil values' do
      expect(result).to eq(described_class.new('key1' => 'value1', 'key3' => 'value3'))
    end

    it 'does not modify the original document' do
      result
      expect(document).to eq(described_class.new('key1' => 'value1', 'key2' => nil, 'key3' => 'value3'))
    end
  end

  describe '#compact!' do
    let(:document) do
      described_class.new('key1' => 'value1', 'key2' => nil, 'key3' => 'value3')
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
        expect(document).to eq(described_class.new('key1' => 'value1', 'key3' => 'value3'))
      end
    end

    context 'when there are no nil values' do
      let(:document) do
        described_class.new('key1' => 'value1', 'key3' => 'value3')
      end

      let(:result) do
        document.compact!
      end

      it 'returns nil' do
        expect(result).to be_nil
      end

      it 'does not modify the original document' do
        result
        expect(document).to eq(described_class.new('key1' => 'value1', 'key3' => 'value3'))
      end
    end
  end

  describe '#slice' do
    context 'with a single-level document' do
      let(:document) do
        described_class.new('key1' => 'value1', 'key2' => 'value2', 'key3' => 'value3')
      end

      let(:result) do
        document.slice('key1', 'key3')
      end

      it 'returns a new BSON::Document' do
        expect(result).to be_a(described_class)
        expect(result).not_to be(document)
      end

      it 'includes only the specified keys' do
        expect(result).to eq(described_class.new('key1' => 'value1', 'key3' => 'value3'))
      end

      it 'does not modify the original document' do
        result
        expect(document).to eq(described_class.new('key1' => 'value1', 'key2' => 'value2', 'key3' => 'value3'))
      end
    end

    context 'when some keys do not exist' do
      let(:document) do
        described_class.new('key1' => 'value1', 'key2' => 'value2')
      end

      let(:result) do
        document.slice('key1', 'nonexistent')
      end

      it 'includes only the existing keys' do
        expect(result).to eq(described_class.new('key1' => 'value1'))
      end
    end

    context 'with symbol keys' do
      let(:document) do
        described_class.new(key1: 'value1', key2: 'value2')
      end

      let(:result) do
        document.slice(:key1)
      end

      it 'handles symbol keys correctly' do
        expect(result).to eq(described_class.new('key1' => 'value1'))
      end
    end
  end

  describe '#transform_keys' do
    let(:document) do
      described_class.new('key1' => 'value1', 'key2' => 'value2', 'key3' => 'value3')
    end

    let(:result) do
      document.transform_keys { |key| key.upcase }
    end

    it 'returns a new BSON::Document' do
      expect(result).to be_a(described_class)
      expect(result).not_to be(document)
    end

    it 'transforms all keys according to the block' do
      expect(result).to eq({ 'KEY1' => 'value1', 'KEY2' => 'value2', 'KEY3' => 'value3' })
    end

    it 'does not modify the original document' do
      result
      expect(document).to eq(described_class.new('key1' => 'value1', 'key2' => 'value2', 'key3' => 'value3'))
    end

    context 'with nested documents' do
      let(:document) do
        described_class.new('outer' => described_class.new('inner' => 'value'))
      end

      let(:result) do
        document.transform_keys { |key| key.upcase }
      end

      it 'does not transform keys in nested documents' do
        expect(result).to eq({ 'OUTER' => { 'inner' => 'value' } })
      end

      it 'keeps nested elements as BSON::Document' do
        expect(result['OUTER']).to be_a(described_class)
      end
    end

    context 'when block not given' do
      let(:enumerator) do
        document.transform_keys
      end

      it 'returns an enumerator' do
        expect(enumerator).to be_a(Enumerator)
      end

      it 'enumerates over all keys' do
        expect(enumerator.to_a).to eq(document.keys)
      end

      it 'produces a BSON::Document when used with a block' do
        result = enumerator.each { |key| key.upcase }
        expect(result).to be_a(described_class)
        expect(result).to eq(described_class.new('KEY1' => 'value1', 'KEY2' => 'value2', 'KEY3' => 'value3'))
      end
    end
  end

  describe '#transform_keys!' do
    let(:document) do
      described_class.new('key1' => 'value1', 'key2' => 'value2', 'key3' => 'value3')
    end

    let(:result) do
      document.transform_keys! { |key| key.upcase }
    end

    it 'returns self' do
      expect(result).to be(document)
    end

    it 'transforms all keys according to the block' do
      result
      expect(document.keys).to eq(%w[KEY1 KEY2 KEY3])
    end

    context 'with nested documents' do
      let(:document) do
        described_class.new('outer' => described_class.new('inner' => 'value'))
      end

      let(:result) do
        document.transform_keys! { |key| key.upcase }
      end

      it 'does not transform keys in nested documents' do
        result
        expect(document['OUTER'].keys).to eq(['inner'])
      end

      it 'preserves nested BSON::Document' do
        result
        expect(document['OUTER']).to be_a(described_class)
      end
    end

    context 'transforming to keys to String' do
      let(:document) do
        described_class.new('key' => :a, 1 => :b)
      end

      let(:action) do
        document.transform_keys!(&:to_s)
      end

      it 'transforms keys to String' do
        action
        expect(document).to eq('key' => :a, '1' => :b)
      end
    end

    context 'transforming to keys to Symbol' do
      let(:document) do
        described_class.new('key' => :a, 1 => :b)
      end

      let(:action) do
        document.transform_keys! { |key| key.is_a?(String) ? key.to_sym : key }
      end

      it 'transforms keys to String' do
        action
        expect(document).to eq('key' => :a, 1 => :b)
      end
    end

    context 'when block not given' do
      let(:enumerator) do
        document.transform_keys!
      end

      it 'returns an enumerator' do
        expect(enumerator).to be_a(Enumerator)
      end

      it 'enumerates over all keys' do
        expect(enumerator.to_a).to eq(%w[key1 key2 key3])

        # Side effect of calling #to_a, same as behavior on Hash.
        expect(document).to eq(nil => 'value3')
      end

      it 'modifies the original document when used with a block' do
        result = document.transform_keys!.each { |key| key.upcase }
        expect(result).to be(document)
        expect(document).to eq(described_class.new('KEY1' => 'value1', 'KEY2' => 'value2', 'KEY3' => 'value3'))
      end
    end
  end

  describe '#transform_values' do
    let(:document) do
      described_class.new('key1' => 'value1', 'key2' => 'value2', 'key3' => 'value3')
    end

    let(:result) do
      document.transform_values { |value| value.upcase }
    end

    it 'returns a new BSON::Document' do
      expect(result).to be_a(described_class)
      expect(result).not_to be(document)
    end

    it 'transforms all values according to the block' do
      expect(result).to eq({ 'key1' => 'VALUE1', 'key2' => 'VALUE2', 'key3' => 'VALUE3' })
    end

    it 'does not modify the original document' do
      result
      expect(document).to eq(described_class.new('key1' => 'value1', 'key2' => 'value2', 'key3' => 'value3'))
    end

    context 'with nested documents' do
      let(:document) do
        described_class.new('key1' => described_class.new('inner' => 'value'))
      end

      let(:result) do
        document.transform_values { |value| value }
      end

      it 'preserves nested documents' do
        original_nested = document['key1']
        nested = result['key1']
        expect(nested).to be_a(described_class)
        expect(nested).to eq(original_nested)
      end
    end

    context 'transforming nested documents' do
      let(:document) do
        described_class.new('key1' => described_class.new('inner' => 'value'))
      end

      let(:result) do
        document.transform_values! { |value| value.is_a?(described_class) ? { foo: :bar, 1 => :a } : value }
      end

      it 'allows transforming nested documents' do
        expect(result).to eq(described_class.new('key1' => { 'foo' => :bar, 1 => :a }))
      end

      it 'converts nested values to BSON::Document' do
        nested = result['key1']
        expect(nested).to be_a(described_class)
        expect(nested.keys).to eq(['foo', 1])
      end
    end

    context 'when block not given' do
      let(:enumerator) do
        document.transform_values
      end

      it 'returns an enumerator' do
        expect(enumerator).to be_a(Enumerator)
      end

      it 'enumerates over all values' do
        expect(enumerator.to_a).to eq(document.values)
      end

      it 'produces a BSON::Document when used with a block' do
        result = enumerator.each { |value| value.upcase }
        expect(result).to be_a(described_class)
        expect(result).to eq(described_class.new('key1' => 'VALUE1', 'key2' => 'VALUE2', 'key3' => 'VALUE3'))
      end

      context 'with nested documents' do
        let(:nested_document) do
          described_class.new('key1' => 'value1', 'nested' => described_class.new('inner' => 'value'))
        end

        let(:nested_enumerator) do
          nested_document.transform_values
        end

        it 'properly handles nested documents when used with a block' do
          result = nested_enumerator.each { |value| value.is_a?(described_class) ? value.dup : value }
          expect(result).to be_a(described_class)
          expect(result['nested']).to be_a(described_class)
          expect(result['nested']).to eq(described_class.new('inner' => 'value'))
        end
      end

      context "enumerator for nested documents" do
        let(:nested_document) do
          described_class.new(
            "key1" => "value1",
            "nested" => described_class.new(
              "inner1" => "value2",
              "inner2" => described_class.new("deep" => "value3")
            )
          )
        end

        it "preserves class of nested documents in transformations" do
          # Using transform_values with an identity block should preserve all types
          result = nested_document.transform_values { |v| v }
          expect(result["nested"]).to be_a(described_class)
          expect(result["nested"]["inner2"]).to be_a(described_class)
        end

        it "allows transforming nested documents with enumerator" do
          doc_copy = nested_document.dup
          # Using transform_values! with an identity block should preserve all types
          doc_copy.transform_values!.each { |v| v }
          expect(doc_copy["nested"]).to be_a(described_class)
          expect(doc_copy["nested"]["inner2"]).to be_a(described_class)
        end
      end

      context "chaining enumerators" do
        it "allows chaining operations on the returned enumerator" do
          result = document.transform_values.with_index do |value, i|
            "#{value}-#{i}"
          end

          expect(result).to be_a(described_class)
          expect(result).to eq(described_class.new(
            "key1" => "value1-0",
            "key2" => "value2-1",
            "key3" => "value3-2"
          ))
        end
      end
    end
  end

  describe '#transform_values!' do
    let(:document) do
      described_class.new('key1' => 'value1', 'key2' => 'value2', 'key3' => 'value3')
    end

    let(:result) do
      document.transform_values! { |value| value.upcase }
    end

    it 'returns self' do
      expect(result).to be(document)
    end

    it 'transforms all values according to the block' do
      result
      expect(document).to eq(described_class.new('key1' => 'VALUE1', 'key2' => 'VALUE2', 'key3' => 'VALUE3'))
    end

    context 'with nested documents' do
      let(:document) do
        described_class.new('key1' => described_class.new('inner' => 'value'))
      end

      let(:action) do
        document.transform_values! { |value| value }
      end

      it 'preserves nested documents' do
        original_nested = document['key1']
        action
        nested = document['key1']
        expect(nested).to be_a(described_class)
        expect(nested).to eq(original_nested)
      end
    end

    context 'transforming nested documents' do
      let(:document) do
        described_class.new('key1' => described_class.new('inner' => 'value'))
      end

      let(:action) do
        document.transform_values! { |value| value.is_a?(described_class) ? { foo: :bar, 1 => :a } : value }
      end

      it 'allows transforming nested documents' do
        action
        expect(document).to eq(described_class.new('key1' => { 'foo' => :bar, 1 => :a }))
      end

      it 'converts nested values to BSON::Document' do
        action
        nested = document['key1']
        expect(nested).to be_a(described_class)
        expect(nested.keys).to eq(['foo', 1])
      end
    end

    context 'when block not given' do
      let(:enumerator) do
        document.dup.transform_values!
      end

      it 'returns an enumerator' do
        expect(enumerator).to be_a(Enumerator)
      end

      it 'enumerates over all values' do
        expect(enumerator.to_a).to eq(document.values)
      end

      it 'modifies the original document when used with a block' do
        doc_copy = document.dup
        result = doc_copy.transform_values!.each { |value| value.upcase }
        expect(result).to be(doc_copy)
        expect(doc_copy).to eq(described_class.new('key1' => 'VALUE1', 'key2' => 'VALUE2', 'key3' => 'VALUE3'))
      end
    end
  end
end
