package binario

import "base:runtime"
import "core:fmt"
import "core:log"


Buff :: struct {
	content: []byte,
	offset:  int,
}


Payload :: struct {
	version: u8,
	size:    u8, // size of the entire buffer
	items:   u8, // how many separate items are in the raw buffer
	raw:     []byte,
}


// Calculates allocation size of v
calc_buff_size :: proc(v: any) -> int {return size_of(v.id) * 4}

// Creates a new [Buff]. It allocates memory
new_buff :: proc(size: int, alloc := context.allocator) -> Buff {
	b := Buff{}
	b.content = make([]byte, size * 4, alloc)
	b.offset = 2
	b.content[0] = VERSION
	b.content[1] = cast(u8)size
	return b
}


// Create a new [Buff]
new_buff_with_content :: proc(size: int, b: []byte) -> Buff {
	bf := Buff{}
	bf.content = b
	bf.content[0] = VERSION
	bf.content[1] = cast(u8)size
	bf.offset = 2
	return bf
}


write :: proc {
	write_byte,
	write_bytes_and_type,
	write_bytes,
}

write_byte :: proc(buff: ^Buff, type: Type, b: byte) -> Error {

	if buff.offset >= len(buff.content) {
		return Error.Full
	}

	buff.content[buff.offset] = cast(u8)type
	buff.offset += 1
	buff.content[buff.offset] = b
	buff.offset += 1
	return nil
}


write_bytes :: proc(buff: ^Buff, b: []byte) -> Error {
	if buff.offset >= len(buff.content) {
		return Error.Full
	}
	copy(buff.content[buff.offset:], b)
	buff.offset += len(b)
	return nil
}


write_bytes_and_type :: proc(buff: ^Buff, type: Type, b: []byte) -> Error {
	if buff.offset >= len(buff.content) {
		return Error.Full
	}
	buff.content[buff.offset] = cast(u8)type
	buff.offset += 1

	copy(buff.content[buff.offset:], b)
	buff.offset += len(b)
	return nil
}


Error :: enum {
	Full,
	EmptySlice,
	WrongVersion,
	SizeZero,
	EOF,
	UnsupportedType,
}

VERSION :: 1

Type :: enum i8 {
	I8,
	I16,
	I32,
	I64,
	I128,
	Int,
	U8,
	U16,
	U32,
	U64,
	U128,
	UInt,
	String, // string
	Boolean, // boolean
	Rune, // rune 32bit integer
	Struct, // struct
	Unsupported,
	//TODO: expand to account for odin specific primitive types like i32be, i32le or complex32 and quaternion64
}


// Typeid to enum
typetoe :: proc(t: typeid) -> Type {
	returnt: Type
	switch t {
	case i8:
		returnt = Type.I8
	case i16:
		returnt = Type.I16
	case i32:
		returnt = Type.I32
	case i64:
		returnt = Type.I64
	case i128:
		returnt = Type.I128
	case int:
		returnt = Type.Int
	case u8:
		returnt = Type.U8
	case u16:
		returnt = Type.U16
	case u32:
		returnt = Type.U32
	case u64:
		returnt = Type.U64
	case u128:
		returnt = Type.U128
	case uint:
		returnt = Type.UInt
	case bool:
		returnt = Type.Boolean
	case string:
		returnt = Type.String
	case rune:
		returnt = Type.Rune
	case:
		returnt = Type.Unsupported
	}
	return returnt
}


@(private)
// Int to bytes
itob :: #force_inline proc(p: rawptr, $N: int) -> [N]byte {
	n := (^[N]u8)(p)
	d: [N]u8
	copy(d[:], n[:])
	return d
}

@(private)
// Bytes to int
btoi :: #force_inline proc(b: []byte, $SIZE: int, $T: typeid) -> (int, T) {
	assert(len(b) >= SIZE, fmt.aprintf("not enough bytes for %s decoding", type_info_of(T)))
	buff: [SIZE]u8
	r := 0
	for v, i in b {
		if i >= SIZE {
			break
		}
		buff[i] = v
		r += 1
	}
	p := rawptr(uintptr(&buff))
	n := (^T)(p)
	return r, n^
}

@(private)
btobool :: proc(b: []byte) -> (int, [1]byte) {
	buff := [1]u8{b[0]}
	r := 1
	return 1, buff
}

// Encode priomitive type that can be cast directly into an integer
encode_primitive_int :: #force_inline proc($T: typeid, $SIZE: int, ptr: rawptr) -> [SIZE + 1]byte {
	arr: [SIZE + 1]byte
	buff := itob(ptr, SIZE)
	arr[0] = u8(typetoe(T))
	copy(arr[1:], buff[:])
	return arr
}

encode_string :: proc(ptr: rawptr, alloc := context.allocator) -> []byte {
	sp := (^string)(ptr)
	slice := make([]byte, len(sp^) + 2, alloc)
	slice[0] = u8(Type.String)
	slice[1] = cast(u8)len(sp^)
	copy(slice[2:], sp[:])
	return slice
}

encode_int :: proc(id: typeid, b: ^Buff, ptr: rawptr) {
	switch id {
	case i8:
		arr := encode_primitive_int(i8, size_of(i8), ptr)
		write(b, arr[:])
	case i16:
		arr := encode_primitive_int(i16, size_of(i16), ptr)
		write(b, arr[:])
	case i32:
		arr := encode_primitive_int(i32, size_of(i32), ptr)
		write(b, arr[:])
	case i64:
		arr := encode_primitive_int(i64, size_of(i64), ptr)
		write(b, arr[:])
	case i128:
		arr := encode_primitive_int(i128, size_of(i128), ptr)
		write(b, arr[:])
	case int:
		arr := encode_primitive_int(int, size_of(int), ptr)
		write(b, arr[:])
	case u8:
		arr := encode_primitive_int(u8, size_of(u8), ptr)
		write(b, arr[:])
	case u16:
		arr := encode_primitive_int(u16, size_of(u16), ptr)
		write(b, arr[:])
	case u32:
		arr := encode_primitive_int(u32, size_of(u32), ptr)
		write(b, arr[:])
	case u64:
		arr := encode_primitive_int(u64, size_of(u64), ptr)
		write(b, arr[:])
	case u128:
		arr := encode_primitive_int(u128, size_of(u128), ptr)
		write(b, arr[:])
	case uint:
		arr := encode_primitive_int(uint, size_of(uint), ptr)
		write(b, arr[:])
	case bool:
		arr := encode_primitive_int(bool, size_of(bool), ptr)
		write(b, arr[:])
	case rune:
		arr := encode_primitive_int(rune, size_of(rune), ptr)
		write(b, arr[:])
	}
}


// Encodes v into slice of bytes returns slize of bytes or error if any. Takes optional buff to avoid
// allocation when creating [Buff]
encode :: proc(
	v: any,
	buff: []byte = nil,
	alloc := context.allocator,
	loc := #caller_location,
) -> (
	[]byte,
	Error,
) {
	ti := runtime.type_info_base(type_info_of(v.id))
	b := buff == nil ? new_buff(ti.size, alloc) : new_buff_with_content(ti.size, buff)

	//NOTE: is there a better way to do this
	#partial switch info in ti.variant {
	case runtime.Type_Info_Integer:
		encode_int(ti.id, &b, v.data)
	case runtime.Type_Info_Boolean:
		encode_int(ti.id, &b, v.data)
	case runtime.Type_Info_Rune:
		encode_int(ti.id, &b, v.data)
	case runtime.Type_Info_String:
		slice := encode_string(v.data)
		defer delete(slice)
		write(&b, slice)
	case runtime.Type_Info_Struct:
		variant := ti.variant.(runtime.Type_Info_Struct)
		types := variant.types
		names := variant.names
		offsets := variant.offsets
		fields := variant.field_count
		for i: i32 = 0; i < fields; i += 1 {
			t := types[i]
			log.infof("%v\n", t)
		}
	case:
		return nil, Error.UnsupportedType
	}


	return b.content[:b.offset], nil
}

// Decodes slice b int v
decode :: proc(b: []byte, v: any, alloc := context.allocator, loc := #caller_location) -> Error {
	b := b

	if len(b) == 0 {
		return Error.EmptySlice
	}

	version := b[0]
	if version != VERSION {
		return Error.WrongVersion
	}

	pl := Payload {
		version = version,
	}

	b = b[1:]
	size := b[0]

	if size == 0 {
		return Error.SizeZero
	}
	pl.size = size
	pl.raw = b[1:]

	for {
		n, e := read(pl.raw, v)
		if e != nil {
			return e
		}
		pl.raw = pl.raw[n:]
	}


	return nil
}


@(private)
read :: proc(
	b: []byte,
	v: any,
	alloc := context.allocator,
	loc := #caller_location,
) -> (
	int,
	Error,
) {
	b := b
	if len(b) == 0 {
		return 0, Error.EOF
	}

	t := b[0]
	read := 1
	b = b[1:]


	// Converts from bytes to int return read bytes
	convert :: #force_inline proc(v: any, $T: typeid, b: []byte) -> int {
		assert(
			v.id == T,
			fmt.aprintf(
				"data type for v does not match source data type. expected %q got %q",
				type_info_of(v.id),
				type_info_of(T),
			),
		)

		r, n := btoi(b, size_of(T), T)
		dest := (^T)(v.data)
		dest^ = n
		return r
	}

	#partial switch cast(Type)t {
	case .I8:
		r := convert(v, i8, b)
		read += r
	case .I16:
		r := convert(v, i16, b)
		read += r
	case .I32:
		r := convert(v, i32, b)
		read += r
	case .I64:
		r := convert(v, i64, b)
		read += r
	case .I128:
		r := convert(v, i128, b)
		read += r
	case .Int:
		r := convert(v, int, b)
		read += r
	case .U8:
		r := convert(v, u8, b)
		read += r
	case .U16:
		r := convert(v, u16, b)
		read += r
	case .U32:
		r := convert(v, u32, b)
		read += r
	case .U64:
		r := convert(v, u64, b)
		read += r
	case .U128:
		r := convert(v, u128, b)
		read += r
	case .UInt:
		r := convert(v, uint, b)
		read += r
	case .Boolean:
		r := convert(v, bool, b)
		read += r
	case .String:
		length := b[0]
		read += 1
		b = b[1:]
		s := (^string)(v.data)
		s^ = string(b[:length])
		read += cast(int)length
	case .Rune:
		r := convert(v, rune, b)
		read += r
	case:
		return 0, Error.UnsupportedType
	}


	return read, nil
}
