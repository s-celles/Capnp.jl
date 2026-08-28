# Generated from test/elementary.capnp
using Capnp
const Test_data_word_count = 2
const Test_pointer_count = 0
function root(message, ::Type{Val{:Test}})
    ptr = Capnp.StructPointer(message, UInt32(1), UInt32(0), UInt16(0), UInt16(1))
    p = Capnp.read_struct_pointer(ptr, 0, 0)
    Capnp.validate_struct_pointer(p, Test_data_word_count, Test_pointer_count, "Test")
    p
end
function root_Test(message)
    Base.depwarn("root_Test is deprecated, use root(message, Val{:Test}) instead", :root_Test)
    root(message, Val{:Test})
end
function init_root!(builder, ::Type{Val{:Test}})
    pointer_location = Capnp.WirePointer(1, 0)
    Capnp.alloc(builder, pointer_location, 8)
    pointer_location, segment, offset = Capnp.alloc(builder, pointer_location, 8*2)
    ptr = Capnp.StructPointer(builder, segment, offset, UInt16(2), UInt16(0))
    Capnp.write_root_struct_pointer(ptr)
    ptr
end
function initRoot_Test(builder)
    Base.depwarn("initRoot_Test is deprecated, use init_root!(builder, Val{:Test}) instead", :initRoot_Test)
    init_root!(builder, Val{:Test})
end
function get_boolean_false(ptr, ::Type{Val{:Test}})
    value = Capnp.read_bool(ptr, 0)
    value
end
function Test_getBooleanFalse(ptr)
    Base.depwarn("Test_getBooleanFalse is deprecated, use get_boolean_false(ptr, Val{:Test}) instead", :Test_getBooleanFalse)
    get_boolean_false(ptr, Val{:Test})
end
function set_boolean_false!(ptr, value, ::Type{Val{:Test}})
    Capnp.write_bool(ptr, 0, value)
end
function Test_setBooleanFalse(ptr, value)
    Base.depwarn("Test_setBooleanFalse is deprecated, use set_boolean_false!(ptr, value, Val{:Test}) instead", :Test_setBooleanFalse)
    set_boolean_false!(ptr, value, Val{:Test})
end
function get_boolean_true(ptr, ::Type{Val{:Test}})
    value = Capnp.read_bool(ptr, 1)
    value
end
function Test_getBooleanTrue(ptr)
    Base.depwarn("Test_getBooleanTrue is deprecated, use get_boolean_true(ptr, Val{:Test}) instead", :Test_getBooleanTrue)
    get_boolean_true(ptr, Val{:Test})
end
function set_boolean_true!(ptr, value, ::Type{Val{:Test}})
    Capnp.write_bool(ptr, 1, value)
end
function Test_setBooleanTrue(ptr, value)
    Base.depwarn("Test_setBooleanTrue is deprecated, use set_boolean_true!(ptr, value, Val{:Test}) instead", :Test_setBooleanTrue)
    set_boolean_true!(ptr, value, Val{:Test})
end
function get_signed64(ptr, ::Type{Val{:Test}})
    value = Capnp.read_bits(ptr, 8, Int64)
    value
end
function Test_getSigned64(ptr)
    Base.depwarn("Test_getSigned64 is deprecated, use get_signed64(ptr, Val{:Test}) instead", :Test_getSigned64)
    get_signed64(ptr, Val{:Test})
end
function set_signed64!(ptr, value, ::Type{Val{:Test}})
    Capnp.write_bits(ptr, 8, Int64, value)
end
function Test_setSigned64(ptr, value)
    Base.depwarn("Test_setSigned64 is deprecated, use set_signed64!(ptr, value, Val{:Test}) instead", :Test_setSigned64)
    set_signed64!(ptr, value, Val{:Test})
end

