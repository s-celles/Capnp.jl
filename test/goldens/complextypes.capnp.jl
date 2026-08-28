# Generated from test/complextypes.capnp
using Capnp
const ComplexFields_data_word_count = 0
const ComplexFields_pointer_count = 3
function root(message, ::Type{Val{:ComplexFields}})
    ptr = Capnp.StructPointer(message, UInt32(1), UInt32(0), UInt16(0), UInt16(1))
    p = Capnp.read_struct_pointer(ptr, 0, 0)
    Capnp.validate_struct_pointer(p, ComplexFields_data_word_count, ComplexFields_pointer_count, "ComplexFields")
    p
end
function root_ComplexFields(message)
    Base.depwarn("root_ComplexFields is deprecated, use root(message, Val{:ComplexFields}) instead", :root_ComplexFields)
    root(message, Val{:ComplexFields})
end
function init_root!(builder, ::Type{Val{:ComplexFields}})
    pointer_location = Capnp.WirePointer(1, 0)
    Capnp.alloc(builder, pointer_location, 8)
    pointer_location, segment, offset = Capnp.alloc(builder, pointer_location, 8*3)
    ptr = Capnp.StructPointer(builder, segment, offset, UInt16(0), UInt16(3))
    Capnp.write_root_struct_pointer(ptr)
    ptr
end
function initRoot_ComplexFields(builder)
    Base.depwarn("initRoot_ComplexFields is deprecated, use init_root!(builder, Val{:ComplexFields}) instead", :initRoot_ComplexFields)
    init_root!(builder, Val{:ComplexFields})
end
function get_data_field(ptr, ::Type{Val{:ComplexFields}})
    p = Capnp.read_list_pointer(ptr, ptr.data_word_count, 0)
    Capnp.read_data(p)
end
function ComplexFields_getDataField(ptr)
    Base.depwarn("ComplexFields_getDataField is deprecated, use get_data_field(ptr, Val{:ComplexFields}) instead", :ComplexFields_getDataField)
    get_data_field(ptr, Val{:ComplexFields})
end
function set_data_field!(ptr, data::AbstractVector{UInt8}, ::Type{Val{:ComplexFields}})
    pointer_location = Capnp.WirePointer(ptr.segment, ptr.offset + ptr.data_word_count + 0)
    pointer_location, segment, offset = Capnp.alloc(ptr.traverser, pointer_location, length(data))
    child_ptr = Capnp.SimpleListPointer{UInt8, typeof(ptr.traverser)}(ptr.traverser, segment, offset, Capnp.Byte, UInt32(length(data)))
    Capnp.write_list_pointer(pointer_location, child_ptr)
    Capnp.write_data(child_ptr, data)
end
function ComplexFields_setDataField(ptr, data::AbstractVector{UInt8})
    Base.depwarn("ComplexFields_setDataField is deprecated, use set_data_field!(ptr, data, Val{:ComplexFields}) instead", :ComplexFields_setDataField)
    set_data_field!(ptr, data, Val{:ComplexFields})
end
function get_list_data_field(ptr::Nothing, ::Type{Val{:ComplexFields}})
    []
end
function ComplexFields_getListDataField(ptr::Nothing)
    Base.depwarn("ComplexFields_getListDataField is deprecated, use get_list_data_field(ptr, Val{:ComplexFields}) instead", :ComplexFields_getListDataField)
    get_list_data_field(ptr, Val{:ComplexFields})
end
function get_list_data_field(ptr, ::Type{Val{:ComplexFields}})
    p = Capnp.read_list_pointer(ptr, ptr.data_word_count, 1, Capnp.CapnpData)
    p
end
function ComplexFields_getListDataField(ptr)
    Base.depwarn("ComplexFields_getListDataField is deprecated, use get_list_data_field(ptr, Val{:ComplexFields}) instead", :ComplexFields_getListDataField)
    get_list_data_field(ptr, Val{:ComplexFields})
end
function init_list_data_field!(ptr, size, ::Type{Val{:ComplexFields}})
    pointer_location = Capnp.WirePointer(ptr.segment, ptr.offset + ptr.data_word_count + 1)
    pointer_location, segment, offset = Capnp.alloc(ptr.traverser, pointer_location, 8 * size)
    child_ptr = Capnp.SimpleListPointer{Capnp.CapnpData, typeof(ptr.traverser)}(ptr.traverser, segment, offset, Capnp.Pointer, convert(UInt32, size))
    Capnp.write_list_pointer(pointer_location, child_ptr)
    child_ptr
end
function ComplexFields_initListDataField(ptr, size)
    Base.depwarn("ComplexFields_initListDataField is deprecated, use init_list_data_field!(ptr, size, Val{:ComplexFields}) instead", :ComplexFields_initListDataField)
    init_list_data_field!(ptr, size, Val{:ComplexFields})
end
function get_any_pointer_field(ptr, ::Type{Val{:ComplexFields}})
    Capnp.read_any_pointer(ptr, ptr.data_word_count, 2)
end
function ComplexFields_getAnyPointerField(ptr)
    Base.depwarn("ComplexFields_getAnyPointerField is deprecated, use get_any_pointer_field(ptr, Val{:ComplexFields}) instead", :ComplexFields_getAnyPointerField)
    get_any_pointer_field(ptr, Val{:ComplexFields})
end

