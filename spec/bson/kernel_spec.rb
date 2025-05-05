# frozen_string_literal: true

# Copyright (C) 2016-2021 MongoDB Inc.
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

describe BSON::Kernel do

  describe 'Hash()' do
    
    context 'when converting BSON::Document' do
      let(:document) do
        BSON::Document.new('key1' => 'value1', 'key2' => 'value2')
      end
  
      let(:hash) do
        Hash(document)
      end
  
      it 'returns a standard Hash' do
        expect(hash).to be_a(Hash)
        expect(hash).not_to be_a(BSON::Document)
      end
  
      it 'preserves the keys and values' do
        expect(hash).to eq({'key1' => 'value1', 'key2' => 'value2'})
      end
    end
  
    context 'when converting BSON::Document with nested documents' do
      let(:nested_document) do
        BSON::Document.new(
          'key1' => 'value1',
          'nested' => BSON::Document.new('inner' => 'value')
        )
      end
  
      let(:hash) do
        Hash(nested_document)
      end
  
      it 'preserves the keys and values' do
        expect(hash).to eq({'key1' => 'value1', 'nested' => {'inner' => 'value'}})
      end
  
      it 'converts nested BSON::Document to Hash' do
        expect(hash['nested']).to be_a(Hash)
        expect(hash['nested']).not_to be_a(BSON::Document)
      end
    end
  
    context 'when converting a hash-like object' do
      let(:hash_like) do
        obj = Object.new
        def obj.to_hash
          {'key1' => 'value1', 'key2' => 'value2'}
        end
        obj
      end
  
      let(:hash) do
        Hash(hash_like)
      end
  
      it 'returns a standard Hash' do
        expect(hash).to be_a(Hash)
      end
  
      it 'uses to_hash method of the object' do
        expect(hash).to eq({'key1' => 'value1', 'key2' => 'value2'})
      end
    end
  
    context 'when converting a BSON::Document with non-string keys' do
      let(:document) do
        doc = BSON::Document.new
        doc[:symbol_key] = 'symbol_value'
        doc[123] = 'numeric_value'
        doc
      end
  
      let(:hash) do
        Hash(document)
      end
  
      it 'preserves the keys as they are in the document' do
        expect(hash.keys).to include('symbol_key', 123)
      end
  
      it 'preserves the values' do
        expect(hash['symbol_key']).to eq('symbol_value')
        expect(hash[123]).to eq('numeric_value')
      end
    end
  
    context 'when converting objects to hashes using Hash()' do
      context 'with a regular Hash' do
        let(:regular_hash) do
          {'key1' => 'value1', 'key2' => 'value2'}
        end
  
        it 'returns the hash unchanged' do
          expect(Hash(regular_hash)).to eq(regular_hash)
          expect(Hash(regular_hash)).to be_a(Hash)
        end
      end
  
      context 'with nil' do
        it 'returns an empty hash' do
          expect(Hash(nil)).to eq({})
          expect(Hash(nil)).to be_a(Hash)
        end
      end

      context 'with an array of pairs' do
        let(:array) do
          [ ['key1', 'value1'], ['key2', 'value2'] ]
        end

        it 'raises TypeError' do
          expect { Hash(array) }.to raise_error(TypeError)
        end
      end

      context 'with an object that does not respond to to_hash' do
        let(:invalid_object) do
          Object.new
        end
  
        it 'raises TypeError' do
          expect { Hash(invalid_object) }.to raise_error(TypeError)
        end
      end
    end
  
    context 'interaction between BSON::Document, Hash() and Ruby hash methods' do
      let(:document) do
        BSON::Document.new('key1' => 'value1', 'key2' => 'value2')
      end
  
      let(:converted_hash) do
        Hash(document)
      end
  
      it 'allows standard Hash methods to be used on the result' do
        expect(converted_hash.keys).to eq(['key1', 'key2'])
        expect(converted_hash.values).to eq(['value1', 'value2'])
        expect(converted_hash.fetch('key1')).to eq('value1')
      end
  
      it 'matches equality with an equivalent Hash' do
        expect(converted_hash).to eq({'key1' => 'value1', 'key2' => 'value2'})
      end
  
      it 'loses indifferent access' do
        expect(document[:key1]).to eq('value1')
        expect(converted_hash[:key1]).to be_nil
        expect(converted_hash['key1']).to eq('value1')
      end
    end
  end
end
