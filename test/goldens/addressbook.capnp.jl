# Generated from example/addressbook.capnp
using Capnp
const qux = 123
@enum Person_PhoneNumber_Type::UInt16 Person_PhoneNumber_Type_mobile=0 Person_PhoneNumber_Type_home=1 Person_PhoneNumber_Type_work=2
const Person_PhoneNumber_data_word_count = 1
const Person_PhoneNumber_pointer_count = 1
function root(message, ::Type{Val{:Person_PhoneNumber}})
    ptr = Capnp.StructPointer(message, UInt32(1), UInt32(0), UInt16(0), UInt16(1))
    p = Capnp.read_struct_pointer(ptr, 0, 0)
    Capnp.validate_struct_pointer(p, Person_PhoneNumber_data_word_count, Person_PhoneNumber_pointer_count, "Person_PhoneNumber")
    p
end
function root_Person_PhoneNumber(message)
    Base.depwarn("root_Person_PhoneNumber is deprecated, use root(message, Val{:Person_PhoneNumber}) instead", :root_Person_PhoneNumber)
    root(message, Val{:Person_PhoneNumber})
end
function init_root!(builder, ::Type{Val{:Person_PhoneNumber}})
    pointer_location = Capnp.WirePointer(1, 0)
    Capnp.alloc(builder, pointer_location, 8)
    pointer_location, segment, offset = Capnp.alloc(builder, pointer_location, 8*2)
    ptr = Capnp.StructPointer(builder, segment, offset, UInt16(1), UInt16(1))
    Capnp.write_root_struct_pointer(ptr)
    ptr
end
function initRoot_Person_PhoneNumber(builder)
    Base.depwarn("initRoot_Person_PhoneNumber is deprecated, use init_root!(builder, Val{:Person_PhoneNumber}) instead", :initRoot_Person_PhoneNumber)
    init_root!(builder, Val{:Person_PhoneNumber})
end
function get_number(ptr, ::Type{Val{:Person_PhoneNumber}})
    p = Capnp.read_list_pointer(ptr, ptr.data_word_count, 0)
    Capnp.read_text(p)
end
function Person_PhoneNumber_getNumber(ptr)
    Base.depwarn("Person_PhoneNumber_getNumber is deprecated, use get_number(ptr, Val{:Person_PhoneNumber}) instead", :Person_PhoneNumber_getNumber)
    get_number(ptr, Val{:Person_PhoneNumber})
end
function set_number!(ptr, txt, ::Type{Val{:Person_PhoneNumber}})
    pointer_location = Capnp.WirePointer(ptr.segment, ptr.offset + ptr.data_word_count + 0)
    pointer_location, segment, offset = Capnp.alloc(ptr.traverser, pointer_location, length(txt) + 1)
    child_ptr = Capnp.SimpleListPointer{UInt8, typeof(ptr.traverser)}(ptr.traverser, segment, offset, Capnp.Byte, UInt32(length(txt) + 1))
    Capnp.write_list_pointer(pointer_location, child_ptr)
    Capnp.write_text(child_ptr, txt)
end
function Person_PhoneNumber_setNumber(ptr, txt)
    Base.depwarn("Person_PhoneNumber_setNumber is deprecated, use set_number!(ptr, txt, Val{:Person_PhoneNumber}) instead", :Person_PhoneNumber_setNumber)
    set_number!(ptr, txt, Val{:Person_PhoneNumber})
end
function get_type(ptr, ::Type{Val{:Person_PhoneNumber}})
    value = Capnp.read_bits(ptr, 0, Person_PhoneNumber_Type)
    value
end
function Person_PhoneNumber_getType(ptr)
    Base.depwarn("Person_PhoneNumber_getType is deprecated, use get_type(ptr, Val{:Person_PhoneNumber}) instead", :Person_PhoneNumber_getType)
    get_type(ptr, Val{:Person_PhoneNumber})
end
function set_type!(ptr, value, ::Type{Val{:Person_PhoneNumber}})
    Capnp.write_bits(ptr, 0, Person_PhoneNumber_Type, value)
end
function Person_PhoneNumber_setType(ptr, value)
    Base.depwarn("Person_PhoneNumber_setType is deprecated, use set_type!(ptr, value, Val{:Person_PhoneNumber}) instead", :Person_PhoneNumber_setType)
    set_type!(ptr, value, Val{:Person_PhoneNumber})
end
const Person_data_word_count = 1
const Person_pointer_count = 4
function root(message, ::Type{Val{:Person}})
    ptr = Capnp.StructPointer(message, UInt32(1), UInt32(0), UInt16(0), UInt16(1))
    p = Capnp.read_struct_pointer(ptr, 0, 0)
    Capnp.validate_struct_pointer(p, Person_data_word_count, Person_pointer_count, "Person")
    p
end
function root_Person(message)
    Base.depwarn("root_Person is deprecated, use root(message, Val{:Person}) instead", :root_Person)
    root(message, Val{:Person})
end
function init_root!(builder, ::Type{Val{:Person}})
    pointer_location = Capnp.WirePointer(1, 0)
    Capnp.alloc(builder, pointer_location, 8)
    pointer_location, segment, offset = Capnp.alloc(builder, pointer_location, 8*5)
    ptr = Capnp.StructPointer(builder, segment, offset, UInt16(1), UInt16(4))
    Capnp.write_root_struct_pointer(ptr)
    ptr
end
function initRoot_Person(builder)
    Base.depwarn("initRoot_Person is deprecated, use init_root!(builder, Val{:Person}) instead", :initRoot_Person)
    init_root!(builder, Val{:Person})
end
function get_id(ptr, ::Type{Val{:Person}})
    value = Capnp.read_bits(ptr, 0, UInt32)
    value
end
function Person_getId(ptr)
    Base.depwarn("Person_getId is deprecated, use get_id(ptr, Val{:Person}) instead", :Person_getId)
    get_id(ptr, Val{:Person})
end
function set_id!(ptr, value, ::Type{Val{:Person}})
    Capnp.write_bits(ptr, 0, UInt32, value)
end
function Person_setId(ptr, value)
    Base.depwarn("Person_setId is deprecated, use set_id!(ptr, value, Val{:Person}) instead", :Person_setId)
    set_id!(ptr, value, Val{:Person})
end
function get_name(ptr, ::Type{Val{:Person}})
    p = Capnp.read_list_pointer(ptr, ptr.data_word_count, 0)
    Capnp.read_text(p)
end
function Person_getName(ptr)
    Base.depwarn("Person_getName is deprecated, use get_name(ptr, Val{:Person}) instead", :Person_getName)
    get_name(ptr, Val{:Person})
end
function set_name!(ptr, txt, ::Type{Val{:Person}})
    pointer_location = Capnp.WirePointer(ptr.segment, ptr.offset + ptr.data_word_count + 0)
    pointer_location, segment, offset = Capnp.alloc(ptr.traverser, pointer_location, length(txt) + 1)
    child_ptr = Capnp.SimpleListPointer{UInt8, typeof(ptr.traverser)}(ptr.traverser, segment, offset, Capnp.Byte, UInt32(length(txt) + 1))
    Capnp.write_list_pointer(pointer_location, child_ptr)
    Capnp.write_text(child_ptr, txt)
end
function Person_setName(ptr, txt)
    Base.depwarn("Person_setName is deprecated, use set_name!(ptr, txt, Val{:Person}) instead", :Person_setName)
    set_name!(ptr, txt, Val{:Person})
end
function get_email(ptr, ::Type{Val{:Person}})
    p = Capnp.read_list_pointer(ptr, ptr.data_word_count, 1)
    Capnp.read_text(p)
end
function Person_getEmail(ptr)
    Base.depwarn("Person_getEmail is deprecated, use get_email(ptr, Val{:Person}) instead", :Person_getEmail)
    get_email(ptr, Val{:Person})
end
function set_email!(ptr, txt, ::Type{Val{:Person}})
    pointer_location = Capnp.WirePointer(ptr.segment, ptr.offset + ptr.data_word_count + 1)
    pointer_location, segment, offset = Capnp.alloc(ptr.traverser, pointer_location, length(txt) + 1)
    child_ptr = Capnp.SimpleListPointer{UInt8, typeof(ptr.traverser)}(ptr.traverser, segment, offset, Capnp.Byte, UInt32(length(txt) + 1))
    Capnp.write_list_pointer(pointer_location, child_ptr)
    Capnp.write_text(child_ptr, txt)
end
function Person_setEmail(ptr, txt)
    Base.depwarn("Person_setEmail is deprecated, use set_email!(ptr, txt, Val{:Person}) instead", :Person_setEmail)
    set_email!(ptr, txt, Val{:Person})
end
function get_phones(ptr::Nothing, ::Type{Val{:Person}})
    []
end
function Person_getPhones(ptr::Nothing)
    Base.depwarn("Person_getPhones is deprecated, use get_phones(ptr, Val{:Person}) instead", :Person_getPhones)
    get_phones(ptr, Val{:Person})
end
function get_phones(ptr, ::Type{Val{:Person}})
    p = Capnp.read_list_pointer(ptr, ptr.data_word_count, 2, Capnp.CapnpStruct)
    Capnp.validate_struct_list_pointer(p, Person_PhoneNumber_data_word_count, Person_PhoneNumber_pointer_count, "Person_PhoneNumber")
    p
end
function Person_getPhones(ptr)
    Base.depwarn("Person_getPhones is deprecated, use get_phones(ptr, Val{:Person}) instead", :Person_getPhones)
    get_phones(ptr, Val{:Person})
end
function init_phones!(ptr, size, ::Type{Val{:Person}})
    pointer_location = Capnp.WirePointer(ptr.segment, ptr.offset + ptr.data_word_count + 2)
    pointer_location, segment, offset = Capnp.alloc(ptr.traverser, pointer_location, 8*(1 + size * (1 + 1)))
    child_ptr = Capnp.CompositeListPointer(ptr.traverser, segment, offset, convert(UInt32, size), UInt16(1), UInt16(1))
    Capnp.write_list_pointer(pointer_location, child_ptr)
    child_ptr
end
function Person_initPhones(ptr, size)
    Base.depwarn("Person_initPhones is deprecated, use init_phones!(ptr, size, Val{:Person}) instead", :Person_initPhones)
    init_phones!(ptr, size, Val{:Person})
end
function get_employment(ptr::Capnp.StructPointer, ::Type{Val{:Person}})
    ptr
end
function Person_getEmployment(ptr::Capnp.StructPointer)
    Base.depwarn("Person_getEmployment is deprecated, use get_employment(ptr, Val{:Person}) instead", :Person_getEmployment)
    get_employment(ptr, Val{:Person})
end
function init_employment!(ptr, ::Type{Val{:Person}})
    ptr
end
function Person_initEmployment(ptr)
    Base.depwarn("Person_initEmployment is deprecated, use init_employment!(ptr, Val{:Person}) instead", :Person_initEmployment)
    init_employment!(ptr, Val{:Person})
end
@enum Person_employment_union::UInt16 Person_employment_union_unemployed Person_employment_union_employer Person_employment_union_school Person_employment_union_selfEmployed 
function which(ptr::Capnp.StructPointer, ::Type{Val{:Person_employment}})
    Person_employment_union(Capnp.read_bits(ptr, 4, UInt16))
end
function Person_employment_which(ptr::Capnp.StructPointer)
    Base.depwarn("Person_employment_which is deprecated, use which(ptr, Val{:Person_employment}) instead", :Person_employment_which)
    which(ptr, Val{:Person_employment})
end
function root(message, ::Type{Val{:Person_employment}})
    ptr = Capnp.StructPointer(message, UInt32(1), UInt32(0), UInt16(0), UInt16(1))
    p = Capnp.read_struct_pointer(ptr, 0, 0)
    Capnp.validate_struct_pointer(p, Person_employment_data_word_count, Person_employment_pointer_count, "Person_employment")
    p
end
function root_Person_employment(message)
    Base.depwarn("root_Person_employment is deprecated, use root(message, Val{:Person_employment}) instead", :root_Person_employment)
    root(message, Val{:Person_employment})
end
function init_root!(builder, ::Type{Val{:Person_employment}})
    pointer_location = Capnp.WirePointer(1, 0)
    Capnp.alloc(builder, pointer_location, 8)
    pointer_location, segment, offset = Capnp.alloc(builder, pointer_location, 8*5)
    ptr = Capnp.StructPointer(builder, segment, offset, UInt16(1), UInt16(4))
    Capnp.write_root_struct_pointer(ptr)
    ptr
end
function initRoot_Person_employment(builder)
    Base.depwarn("initRoot_Person_employment is deprecated, use init_root!(builder, Val{:Person_employment}) instead", :initRoot_Person_employment)
    init_root!(builder, Val{:Person_employment})
end
function set_unemployed!(ptr, ::Type{Val{:Person_employment}})
    Capnp.write_bits(ptr, 4, UInt16, 0) # union discriminant
end
function Person_employment_setUnemployed(ptr)
    Base.depwarn("Person_employment_setUnemployed is deprecated, use set_unemployed!(ptr, Val{:Person_employment}) instead", :Person_employment_setUnemployed)
    set_unemployed!(ptr, Val{:Person_employment})
end
function get_employer(ptr, ::Type{Val{:Person_employment}})
    p = Capnp.read_list_pointer(ptr, ptr.data_word_count, 3)
    Capnp.read_text(p)
end
function Person_employment_getEmployer(ptr)
    Base.depwarn("Person_employment_getEmployer is deprecated, use get_employer(ptr, Val{:Person_employment}) instead", :Person_employment_getEmployer)
    get_employer(ptr, Val{:Person_employment})
end
function set_employer!(ptr, txt, ::Type{Val{:Person_employment}})
    pointer_location = Capnp.WirePointer(ptr.segment, ptr.offset + ptr.data_word_count + 3)
    pointer_location, segment, offset = Capnp.alloc(ptr.traverser, pointer_location, length(txt) + 1)
    child_ptr = Capnp.SimpleListPointer{UInt8, typeof(ptr.traverser)}(ptr.traverser, segment, offset, Capnp.Byte, UInt32(length(txt) + 1))
    Capnp.write_list_pointer(pointer_location, child_ptr)
    Capnp.write_bits(ptr, 4, UInt16, 1) # union discriminant
    Capnp.write_text(child_ptr, txt)
end
function Person_employment_setEmployer(ptr, txt)
    Base.depwarn("Person_employment_setEmployer is deprecated, use set_employer!(ptr, txt, Val{:Person_employment}) instead", :Person_employment_setEmployer)
    set_employer!(ptr, txt, Val{:Person_employment})
end
function get_school(ptr, ::Type{Val{:Person_employment}})
    p = Capnp.read_list_pointer(ptr, ptr.data_word_count, 3)
    Capnp.read_text(p)
end
function Person_employment_getSchool(ptr)
    Base.depwarn("Person_employment_getSchool is deprecated, use get_school(ptr, Val{:Person_employment}) instead", :Person_employment_getSchool)
    get_school(ptr, Val{:Person_employment})
end
function set_school!(ptr, txt, ::Type{Val{:Person_employment}})
    pointer_location = Capnp.WirePointer(ptr.segment, ptr.offset + ptr.data_word_count + 3)
    pointer_location, segment, offset = Capnp.alloc(ptr.traverser, pointer_location, length(txt) + 1)
    child_ptr = Capnp.SimpleListPointer{UInt8, typeof(ptr.traverser)}(ptr.traverser, segment, offset, Capnp.Byte, UInt32(length(txt) + 1))
    Capnp.write_list_pointer(pointer_location, child_ptr)
    Capnp.write_bits(ptr, 4, UInt16, 2) # union discriminant
    Capnp.write_text(child_ptr, txt)
end
function Person_employment_setSchool(ptr, txt)
    Base.depwarn("Person_employment_setSchool is deprecated, use set_school!(ptr, txt, Val{:Person_employment}) instead", :Person_employment_setSchool)
    set_school!(ptr, txt, Val{:Person_employment})
end
function set_self_employed!(ptr, ::Type{Val{:Person_employment}})
    Capnp.write_bits(ptr, 4, UInt16, 3) # union discriminant
end
function Person_employment_setSelfEmployed(ptr)
    Base.depwarn("Person_employment_setSelfEmployed is deprecated, use set_self_employed!(ptr, Val{:Person_employment}) instead", :Person_employment_setSelfEmployed)
    set_self_employed!(ptr, Val{:Person_employment})
end
const AddressBook_data_word_count = 0
const AddressBook_pointer_count = 1
function root(message, ::Type{Val{:AddressBook}})
    ptr = Capnp.StructPointer(message, UInt32(1), UInt32(0), UInt16(0), UInt16(1))
    p = Capnp.read_struct_pointer(ptr, 0, 0)
    Capnp.validate_struct_pointer(p, AddressBook_data_word_count, AddressBook_pointer_count, "AddressBook")
    p
end
function root_AddressBook(message)
    Base.depwarn("root_AddressBook is deprecated, use root(message, Val{:AddressBook}) instead", :root_AddressBook)
    root(message, Val{:AddressBook})
end
function init_root!(builder, ::Type{Val{:AddressBook}})
    pointer_location = Capnp.WirePointer(1, 0)
    Capnp.alloc(builder, pointer_location, 8)
    pointer_location, segment, offset = Capnp.alloc(builder, pointer_location, 8*1)
    ptr = Capnp.StructPointer(builder, segment, offset, UInt16(0), UInt16(1))
    Capnp.write_root_struct_pointer(ptr)
    ptr
end
function initRoot_AddressBook(builder)
    Base.depwarn("initRoot_AddressBook is deprecated, use init_root!(builder, Val{:AddressBook}) instead", :initRoot_AddressBook)
    init_root!(builder, Val{:AddressBook})
end
function get_people(ptr::Nothing, ::Type{Val{:AddressBook}})
    []
end
function AddressBook_getPeople(ptr::Nothing)
    Base.depwarn("AddressBook_getPeople is deprecated, use get_people(ptr, Val{:AddressBook}) instead", :AddressBook_getPeople)
    get_people(ptr, Val{:AddressBook})
end
function get_people(ptr, ::Type{Val{:AddressBook}})
    p = Capnp.read_list_pointer(ptr, ptr.data_word_count, 0, Capnp.CapnpStruct)
    Capnp.validate_struct_list_pointer(p, Person_data_word_count, Person_pointer_count, "Person")
    p
end
function AddressBook_getPeople(ptr)
    Base.depwarn("AddressBook_getPeople is deprecated, use get_people(ptr, Val{:AddressBook}) instead", :AddressBook_getPeople)
    get_people(ptr, Val{:AddressBook})
end
function init_people!(ptr, size, ::Type{Val{:AddressBook}})
    pointer_location = Capnp.WirePointer(ptr.segment, ptr.offset + ptr.data_word_count + 0)
    pointer_location, segment, offset = Capnp.alloc(ptr.traverser, pointer_location, 8*(1 + size * (1 + 4)))
    child_ptr = Capnp.CompositeListPointer(ptr.traverser, segment, offset, convert(UInt32, size), UInt16(1), UInt16(4))
    Capnp.write_list_pointer(pointer_location, child_ptr)
    child_ptr
end
function AddressBook_initPeople(ptr, size)
    Base.depwarn("AddressBook_initPeople is deprecated, use init_people!(ptr, size, Val{:AddressBook}) instead", :AddressBook_initPeople)
    init_people!(ptr, size, Val{:AddressBook})
end

