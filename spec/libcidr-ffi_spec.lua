describe("libcidr-ffi", function()
  local cidr = require "libcidr-ffi"

  describe("from_str", function()
    it("parses an ipv4 address", function()
      local result, err = cidr.from_str("1.1.1.1")
      assert.are.equal(type(result), "cdata")
      assert.are.equal(err, nil)
    end)

    it("parses an ipv4 address with cidr notation", function()
      local result, err = cidr.from_str("1.1.1.1/8")
      assert.are.equal(type(result), "cdata")
      assert.are.equal(err, nil)
    end)

    it("parses an ipv6 address", function()
      local result, err = cidr.from_str("fe80:0000:0000:0000:0202:b3ff:fe1e:8329")
      assert.are.equal(type(result), "cdata")
      assert.are.equal(err, nil)
    end)

    it("parses an ipv6 address with cidr notation", function()
      local result, err = cidr.from_str("fe80:0000:0000:0000:0202:b3ff:fe1e:8329/32")
      assert.are.equal(type(result), "cdata")
      assert.are.equal(err, nil)
    end)

    it("parses a collapsed ipv6 address", function()
      local result, err = cidr.from_str("2001:db8:3c4d:15:0:d234:3eee::")
      assert.are.equal(type(result), "cdata")
      assert.are.equal(err, nil)
    end)

    it("parses a collapsed ipv6 address with cidr notation", function()
      local result, err = cidr.from_str("2001:db8:3c4d:15:0:d234:3eee::/16")
      assert.are.equal(type(result), "cdata")
      assert.are.equal(err, nil)
    end)

    it("returns an error when passed nil", function()
      local result, err = cidr.from_str(nil)
      assert.are.equal(result, nil)
      assert.are.equal(err, "Passed NULL")
    end)

    it("returns an error when passed an invalid address", function()
      local result, err = cidr.from_str("foo")
      assert.are.equal(result, nil)
      assert.are.equal(err, "Can't parse the input string")
    end)
  end)

  describe("to_str", function()
    it("translates a from_str ipv4 struct into a string", function()
      local result, err = cidr.to_str(cidr.from_str("1.1.1.1"))
      assert.are.equal(result, "1.1.1.1/32")
      assert.are.equal(err, nil)
    end)

    it("translates a from_str ipv4 struct into a string", function()
      local result, err = cidr.to_str(cidr.from_str("2001:db8:3c4d:15:0:d234:3eee::/16"))
      assert.are.equal(result, "2001:db8:3c4d:15::d234:3eee:0/16")
      assert.are.equal(err, nil)
    end)

    it("returns an error when passed nil", function()
      local result, err = cidr.to_str(nil)
      assert.are.equal(result, nil)
      assert.are.equal(err, "Invalid argument (bad block or flags)")
    end)

    it("returns an error when passed unexpected types", function()
      local result, err = cidr.to_str("1.1.1.1")
      assert.are.equal(result, nil)
      assert.are.equal(err, "Invalid argument (bad block or flags)")

      result, err = cidr.to_str({ foo = "bar" })
      assert.are.equal(result, nil)
      assert.are.equal(err, "Invalid argument (bad block or flags)")

      result, err = cidr.to_str(true)
      assert.are.equal(result, nil)
      assert.are.equal(err, "Invalid argument (bad block or flags)")
    end)

    it("returns VERBOSE - Don't minimize leading zeros", function()
      local result, err = cidr.to_str( cidr.from_str("2001:db8::2:1"), cidr.flags.VERBOSE )
      assert.are.equal(result, "2001:0db8::0002:0001/128")
      assert.are.equal(err, nil)
    end)

    it("returns VERBOSE and NOCOMPACT - Don't do :: compaction", function()
      local result, err = cidr.to_str( cidr.from_str("2001:db8::2:1"), bit.bor(cidr.flags.NOCOMPACT, cidr.flags.VERBOSE) )
      assert.are.equal(result, "2001:0db8:0000:0000:0000:0000:0002:0001/128")
      assert.are.equal(err, nil)
    end)

    it("returns only the address without netmask", function()
      local result, err = cidr.to_str( cidr.from_str("2001:db8::2:1"), cidr.flags.ONLYADDR )
      assert.are.equal(result, "2001:db8::2:1")
      assert.are.equal(err, nil)
    end)

    it("returns an error with invalid flags", function()
      local result, err = cidr.to_str( cidr.from_str("2001:db8::2:1"), -1 )
      assert.are.equal(result, nil)
      assert.are.equal(err, "Invalid argument (bad block or flags)")
    end)

    it("returns flags = 0 (no flags) as default when unsupported type is sent", function()
      local result, err = cidr.to_str( cidr.from_str("2001:db8::2:1"), {} )
      assert.are.equal(result, "2001:db8::2:1/128")
      assert.are.equal(err, nil)

      result, err = cidr.to_str( cidr.from_str("2001:db8::2:1"), "a string" )
      assert.are.equal(result, "2001:db8::2:1/128")
      assert.are.equal(err, nil)

      result, err = cidr.to_str( cidr.from_str("2001:db8::2:1"), function() end )
      assert.are.equal(result, "2001:db8::2:1/128")
      assert.are.equal(err, nil)
    end)
  end)

  describe("contains", function()
    it("returns true when an ipv4 cidr range contains an ip address", function()
      local result, err = cidr.contains(cidr.from_str("10.10.10.10/8"), cidr.from_str("10.20.30.40"))
      assert.are.equal(result, true)
      assert.are.equal(err, nil)
    end)

    it("returns false when an ipv4 cidr range does not contain an ip address", function()
      local result, err = cidr.contains(cidr.from_str("10.10.10.10/16"), cidr.from_str("10.20.30.40"))
      assert.are.equal(result, false)
      assert.are.equal(err, nil)
    end)

    it("returns an error when passed an ipv4 address and ipv6 range", function()
      local result, err = cidr.contains(cidr.from_str("2001:db8:3c4d:15:0:d234:3eee::/16"), cidr.from_str("10.20.30.40"))
      assert.are.equal(result, nil)
      assert.are.equal(err, "Protocols don't match")
    end)

    it("returns an error when passed an ipv6 address and ipv4 range", function()
      local result, err = cidr.contains(cidr.from_str("10.10.10.10/8"), cidr.from_str("2001:db8:3c4d:15:0:d234:3eee::"))
      assert.are.equal(result, nil)
      assert.are.equal(err, "Protocols don't match")
    end)

    it("returns true when a larger cidr range contains the smaller cidr range", function()
      local result, err = cidr.contains(cidr.from_str("10.10.10.10/8"), cidr.from_str("10.20.30.40/16"))
      assert.are.equal(result, true)
      assert.are.equal(err, nil)
    end)

    it("returns false when a smaller cidr range does not contains the bigger cidr range", function()
      local result, err = cidr.contains(cidr.from_str("10.10.10.10/16"), cidr.from_str("10.20.30.40/8"))
      assert.are.equal(result, false)
      assert.are.equal(err, nil)
    end)

    it("returns an error when passed an nil for the range", function()
      local result, err = cidr.contains(nil, cidr.from_str("10.20.30.40"))
      assert.are.equal(result, nil)
      assert.are.equal(err, "Passed NULL")
    end)

    it("returns an error when passed an nil for the ip", function()
      local result, err = cidr.contains(cidr.from_str("10.10.10.10/8"), nil)
      assert.are.equal(result, nil)
      assert.are.equal(err, "Passed NULL")
    end)

    it("returns an error when passed unexpected value for the range", function()
      local result, err = cidr.contains("foo", cidr.from_str("10.20.30.40"))
      assert.are.equal(result, nil)
      assert.are.equal(err, "Invalid argument")
    end)

    it("returns an error when passed unexpected value for the ip", function()
      local result, err = cidr.contains(cidr.from_str("10.10.10.10/8"), true)
      assert.are.equal(result, nil)
      assert.are.equal(err, "Invalid argument")
    end)
  end)
end)
