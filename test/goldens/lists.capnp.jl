# Generated from test/lists.capnp
using Capnp
const ListTest_data_word_count = 0
const ListTest_pointer_count = 5
function root(message, ::Type{Val{:ListTest}})
    ptr = Capnp.StructPointer(message, UInt32(1), UInt32(0), UInt16(0), UInt16(1))
    p = Capnp.read_struct_pointer(ptr, 0, 0)
    Capnp.validate_struct_pointer(p, ListTest_data_word_count, ListTest_pointer_count, "ListTest")
    p
end
function root_ListTest(message)
    Base.depwarn("root_ListTest is deprecated, use root(message, Val{:ListTest}) instead", :root_ListTest)
    root(message, Val{:ListTest})
end
function init_root!(builder, ::Type{Val{:ListTest}})
    pointer_location = Capnp.WirePointer(1, 0)
    Capnp.alloc(builder, pointer_location, 8)
    pointer_location, segment, offset = Capnp.alloc(builder, pointer_location, 8*5)
    ptr = Capnp.StructPointer(builder, segment, offset, UInt16(0), UInt16(5))
    Capnp.write_root_struct_pointer(ptr)
    ptr
end
function initRoot_ListTest(builder)
    Base.depwarn("initRoot_ListTest is deprecated, use init_root!(builder, Val{:ListTest}) instead", :initRoot_ListTest)
    init_root!(builder, Val{:ListTest})
end
function get_bytes(ptr::Nothing, ::Type{Val{:ListTest}})
    []
end
function ListTest_getBytes(ptr::Nothing)
    Base.depwarn("ListTest_getBytes is deprecated, use get_bytes(ptr, Val{:ListTest}) instead", :ListTest_getBytes)
    get_bytes(ptr, Val{:ListTest})
end
function get_bytes(ptr, ::Type{Val{:ListTest}})
    p = Capnp.read_list_pointer(ptr, ptr.data_word_count, 0, Capnp.CapnpUInt8)
    p
end
function ListTest_getBytes(ptr)
    Base.depwarn("ListTest_getBytes is deprecated, use get_bytes(ptr, Val{:ListTest}) instead", :ListTest_getBytes)
    get_bytes(ptr, Val{:ListTest})
end
function init_bytes!(ptr, size, ::Type{Val{:ListTest}})
    pointer_location = Capnp.WirePointer(ptr.segment, ptr.offset + ptr.data_word_count + 0)
    pointer_location, segment, offset = Capnp.alloc(ptr.traverser, pointer_location, 1 * size)
    child_ptr = Capnp.SimpleListPointer{Capnp.CapnpUInt8, typeof(ptr.traverser)}(ptr.traverser, segment, offset, Capnp.Byte, convert(UInt32, size))
    Capnp.write_list_pointer(pointer_location, child_ptr)
    child_ptr
end
function ListTest_initBytes(ptr, size)
    Base.depwarn("ListTest_initBytes is deprecated, use init_bytes!(ptr, size, Val{:ListTest}) instead", :ListTest_initBytes)
    init_bytes!(ptr, size, Val{:ListTest})
end
function get_ints(ptr::Nothing, ::Type{Val{:ListTest}})
    []
end
function ListTest_getInts(ptr::Nothing)
    Base.depwarn("ListTest_getInts is deprecated, use get_ints(ptr, Val{:ListTest}) instead", :ListTest_getInts)
    get_ints(ptr, Val{:ListTest})
end
function get_ints(ptr, ::Type{Val{:ListTest}})
    p = Capnp.read_list_pointer(ptr, ptr.data_word_count, 1, Capnp.CapnpInt32)
    p
end
function ListTest_getInts(ptr)
    Base.depwarn("ListTest_getInts is deprecated, use get_ints(ptr, Val{:ListTest}) instead", :ListTest_getInts)
    get_ints(ptr, Val{:ListTest})
end
function init_ints!(ptr, size, ::Type{Val{:ListTest}})
    pointer_location = Capnp.WirePointer(ptr.segment, ptr.offset + ptr.data_word_count + 1)
    pointer_location, segment, offset = Capnp.alloc(ptr.traverser, pointer_location, 4 * size)
    child_ptr = Capnp.SimpleListPointer{Capnp.CapnpInt32, typeof(ptr.traverser)}(ptr.traverser, segment, offset, Capnp.FourBytes, convert(UInt32, size))
    Capnp.write_list_pointer(pointer_location, child_ptr)
    child_ptr
end
function ListTest_initInts(ptr, size)
    Base.depwarn("ListTest_initInts is deprecated, use init_ints!(ptr, size, Val{:ListTest}) instead", :ListTest_initInts)
    init_ints!(ptr, size, Val{:ListTest})
end
function get_texts(ptr::Nothing, ::Type{Val{:ListTest}})
    []
end
function ListTest_getTexts(ptr::Nothing)
    Base.depwarn("ListTest_getTexts is deprecated, use get_texts(ptr, Val{:ListTest}) instead", :ListTest_getTexts)
    get_texts(ptr, Val{:ListTest})
end
function get_texts(ptr, ::Type{Val{:ListTest}})
    p = Capnp.read_list_pointer(ptr, ptr.data_word_count, 2, Capnp.CapnpText)
    p
end
function ListTest_getTexts(ptr)
    Base.depwarn("ListTest_getTexts is deprecated, use get_texts(ptr, Val{:ListTest}) instead", :ListTest_getTexts)
    get_texts(ptr, Val{:ListTest})
end
function init_texts!(ptr, size, ::Type{Val{:ListTest}})
    pointer_location = Capnp.WirePointer(ptr.segment, ptr.offset + ptr.data_word_count + 2)
    pointer_location, segment, offset = Capnp.alloc(ptr.traverser, pointer_location, 8 * size)
    child_ptr = Capnp.SimpleListPointer{Capnp.CapnpText, typeof(ptr.traverser)}(ptr.traverser, segment, offset, Capnp.Pointer, convert(UInt32, size))
    Capnp.write_list_pointer(pointer_location, child_ptr)
    child_ptr
end
function ListTest_initTexts(ptr, size)
    Base.depwarn("ListTest_initTexts is deprecated, use init_texts!(ptr, size, Val{:ListTest}) instead", :ListTest_initTexts)
    init_texts!(ptr, size, Val{:ListTest})
end
function get_lists(ptr::Nothing, ::Type{Val{:ListTest}})
    []
end
function ListTest_getLists(ptr::Nothing)
    Base.depwarn("ListTest_getLists is deprecated, use get_lists(ptr, Val{:ListTest}) instead", :ListTest_getLists)
    get_lists(ptr, Val{:ListTest})
end
function get_lists(ptr, ::Type{Val{:ListTest}})
    p = Capnp.read_list_pointer(ptr, ptr.data_word_count, 3, Capnp.CapnpList{Capnp.CapnpInt32})
    p
end
function ListTest_getLists(ptr)
    Base.depwarn("ListTest_getLists is deprecated, use get_lists(ptr, Val{:ListTest}) instead", :ListTest_getLists)
    get_lists(ptr, Val{:ListTest})
end
function init_lists!(ptr, size, ::Type{Val{:ListTest}})
    pointer_location = Capnp.WirePointer(ptr.segment, ptr.offset + ptr.data_word_count + 3)
    pointer_location, segment, offset = Capnp.alloc(ptr.traverser, pointer_location, 8 * size)
    child_ptr = Capnp.SimpleListPointer{Capnp.CapnpList{Capnp.CapnpInt32}, typeof(ptr.traverser)}(ptr.traverser, segment, offset, Capnp.Pointer, convert(UInt32, size))
    Capnp.write_list_pointer(pointer_location, child_ptr)
    child_ptr
end
function ListTest_initLists(ptr, size)
    Base.depwarn("ListTest_initLists is deprecated, use init_lists!(ptr, size, Val{:ListTest}) instead", :ListTest_initLists)
    init_lists!(ptr, size, Val{:ListTest})
end
function get_data_list(ptr::Nothing, ::Type{Val{:ListTest}})
    []
end
function ListTest_getDataList(ptr::Nothing)
    Base.depwarn("ListTest_getDataList is deprecated, use get_data_list(ptr, Val{:ListTest}) instead", :ListTest_getDataList)
    get_data_list(ptr, Val{:ListTest})
end
function get_data_list(ptr, ::Type{Val{:ListTest}})
    p = Capnp.read_list_pointer(ptr, ptr.data_word_count, 4, Capnp.CapnpData)
    p
end
function ListTest_getDataList(ptr)
    Base.depwarn("ListTest_getDataList is deprecated, use get_data_list(ptr, Val{:ListTest}) instead", :ListTest_getDataList)
    get_data_list(ptr, Val{:ListTest})
end
function init_data_list!(ptr, size, ::Type{Val{:ListTest}})
    pointer_location = Capnp.WirePointer(ptr.segment, ptr.offset + ptr.data_word_count + 4)
    pointer_location, segment, offset = Capnp.alloc(ptr.traverser, pointer_location, 8 * size)
    child_ptr = Capnp.SimpleListPointer{Capnp.CapnpData, typeof(ptr.traverser)}(ptr.traverser, segment, offset, Capnp.Pointer, convert(UInt32, size))
    Capnp.write_list_pointer(pointer_location, child_ptr)
    child_ptr
end
function ListTest_initDataList(ptr, size)
    Base.depwarn("ListTest_initDataList is deprecated, use init_data_list!(ptr, size, Val{:ListTest}) instead", :ListTest_initDataList)
    init_data_list!(ptr, size, Val{:ListTest})
end

