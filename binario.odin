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


write_bytes :: proc(buff: ^Buff, type: Type, b: []byte) -> Error {
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

	//TODO: expand to account for odin specific primitive types like i32be, i32le or complex32 and quaternion64
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

	switch ti.id {
	case i8:
		byts := itob(v.data, size_of(i8))
		write(&b, Type.I8, byts[:])
	case i16:
		byts := itob(v.data, size_of(i16))
		write(&b, Type.I16, byts[:])
	case i32:
		byts := itob(v.data, size_of(i32))
		write(&b, Type.I32, byts[:])
	case i64:
		byts := itob(v.data, size_of(i64))
		write(&b, Type.I64, byts[:])
	case i128:
		byts := itob(v.data, size_of(i128))
		write(&b, Type.I128, byts[:])
	case int:
		byts := itob(v.data, size_of(int))
		write(&b, Type.Int, byts[:])
	case u8:
		byts := itob(v.data, size_of(u8))
		write(&b, Type.U8, byts[:])
	case u16:
		byts := itob(v.data, size_of(u16))
		write(&b, Type.U16, byts[:])
	case u32:
		byts := itob(v.data, size_of(u32))
		write(&b, Type.U32, byts[:])
	case u64:
		byts := itob(v.data, size_of(u64))
		write(&b, Type.U64, byts[:])
	case u128:
		byts := itob(v.data, size_of(u128))
		write(&b, Type.U128, byts[:])
	case uint:
		byts := itob(v.data, size_of(uint))
		write(&b, Type.UInt, byts[:])
	case bool:
		byts := itob(v.data, size_of(bool))
		write(&b, Type.Boolean, byts[:])
	case string:
		//NOTE: needs testing
		rp := rawptr(uintptr(v.data))
		sp := (^string)(rp)
		byts := make([]byte, len(sp^) + 1, alloc)
		byts[0] = cast(u8)len(sp^)
		defer delete(byts, alloc)
		copy(byts[1:], sp[:])
		write(&b, Type.String, byts)
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
	case:
		return 0, Error.UnsupportedType
	}


	return read, nil
}
