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

module BSON

  # Monkey patch which injects behavior so that Hash() correctly
  # handles BSON::Document.
  module Kernel

    # Returns a hash converted from object and correctly handles BSON::Document.
    # This patch causes the kernel Hash() method to slow from ~5 nanoseconds to
    # ~10 nanoseconds, which is acceptable considering it is not called
    # commonly (e.g. in major libraries such as Rails.)
    #
    # @param [ Object ] object The object to convert to a hash.
    #
    # @return [ Hash ] The hash representation of the object.
    def Hash(object)
      return object.to_hash if object.is_a?(BSON::Document)

      super
    end
  end

  # Prepend the core Kernel class with this module.
  ::Kernel.prepend(Kernel)
end
