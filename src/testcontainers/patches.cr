# Monkey-patch for docr types that are missing JSON::Serializable
# This fixes a bug in docr where ExecConfig doesn't include JSON::Serializable
# even though it has JSON::Field annotations.

module Docr::Types
  class ExecConfig
    include JSON::Serializable
  end
end
