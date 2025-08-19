package binario

import "base:intrinsics"
import "base:runtime"
import "core:fmt"
import "core:log"
import "core:mem"

VERSION: u8 : 0

// bytes reserve for meta data
META_BYTES_PADDING: u32 : 5

Payload :: struct {
	version: u8,
	size:    u8, // size of the entire buffer
	items:   u8, // how many separate items are in the raw buffer
	raw:     []byte,
}


@(private)
// Convert an int to bytes
itob :: #force_inline proc(p: rawptr, $N: int) -> [N]byte {
	n := (^[N]u8)(p)
	d: [N]u8
	copy(d[:], n[:])
	return d
}

//where intrinsics.type_is_integer(T) 
@(private)
// Converts a slice of bytes into an integer returns read bytes plus int of type T
btoi :: #force_inline proc(b: []byte, $SIZE: int, $T: typeid) -> (read: int, value: T) {
	assert(len(b) >= SIZE, fmt.aprintf("not enough bytes for %s decoding", type_info_of(T)))
	buff: [SIZE]u8
	read = 0
	for v, i in b {
		if i >= SIZE {
			break
		}
		buff[i] = v
		read += 1
	}
	p := rawptr(uintptr(&buff))
	n := (^T)(p)
	return read, n^
}

@(private)
// Converts bytes to bool
bytes_to_bool :: proc(bytes: []byte) -> (bool, Error) {
	if bytes == nil do return false, Error.EmptySlice

	assert(
		len(bytes) == 1,
		"slice it too big for boolean convertion a slice of 1 bytes is required",
	)

	byte := bytes[0]

	if byte == 1 do return true, nil
	else if byte == 0 do return false, nil

	return false, Error.BoolByteOutOfRange
}

@(private)
// Converts a boolean to bytes
bool_to_bytes :: proc(b: bool) -> [1]byte {
	bytes := [1]byte{cast(u8)b}
	return bytes
}

// Encode primitive type that can be cast directly into an integer
encode_primitive_int :: #force_inline proc(
	$T: typeid,
	$SIZE: int,
	ptr: rawptr,
	offset := -1,
) -> [SIZE]byte {
	//NOTE: i forgot why i did this
	ptr := offset == -1 ? ptr : rawptr(uintptr(mem.ptr_offset((^T)(ptr), offset)))

	arr: [SIZE]byte
	buff := itob(ptr, SIZE)
	copy(arr[:], buff[:])
	return arr
}

// Enodes string type to bytes
encode_string :: proc(ptr: rawptr, alloc := context.allocator) -> []byte {
	sp := (^string)(ptr)
	slice := make([]byte, len(sp^) + 2, alloc)
	slice[0] = u8(Type.String)
	slice[1] = cast(u8)len(sp^)
	copy(slice[2:], sp[:])
	return slice
}


// encode_struct :: proc(variant: runtime.Type_Info_Struct, b: ^Buff, size: int, ptr: rawptr) {
// 	write(b, Type.Struct, size)
// 	types := variant.types
// 	names := variant.names
// 	offsets := variant.offsets
// 	fields := variant.field_count
// 	for i: i32 = 0; i < fields; i += 1 {
// 		t := types[i]
// 		name := names[i]
// 		log.info(name, len(name))
// 		#partial switch info in t.variant {
// 		//TODO: finish encoding structs
// 		case runtime.Type_Info_Integer:
// 			encode_int(t.id, b, ptr, int(offsets[i]))
// 		}
// 	}
// }

// Encodes integer to bytes
encode_int :: proc(id: typeid, buffer: ^Buff, ptr: rawptr, offset := -1) -> Error {
	switch id {
	case i8:
		buff_write_type(buffer, i8) or_return
		bytes := itob(ptr, size_of(i8))
		buff_write(buffer, bytes[:])
	// arr := encode_primitive_int(i8, size_of(i8), ptr, offset)
	case i16:
		buff_write_type(buffer, i16) or_return
		arr := encode_primitive_int(i16, size_of(i16), ptr, offset)
		buff_write(buffer, arr[:])
	case i32:
		buff_write_type(buffer, i32)
		arr := encode_primitive_int(i32, size_of(i32), ptr, offset)
		buff_write(buffer, arr[:])
	case i64:
		buff_write_type(buffer, i64)
		arr := encode_primitive_int(i64, size_of(i64), ptr, offset)
		buff_write(buffer, arr[:])
	case i128:
		buff_write_type(buffer, i128)
		arr := encode_primitive_int(i128, size_of(i128), ptr, offset)
		buff_write(buffer, arr[:])
	case int:
		buff_write_type(buffer, int)
		arr := encode_primitive_int(int, size_of(int), ptr, offset)
		buff_write(buffer, arr[:])
	case u8:
		buff_write_type(buffer, u8)
		arr := encode_primitive_int(u8, size_of(u8), ptr, offset)
		buff_write(buffer, arr[:])
	case u16:
		buff_write_type(buffer, u16)
		arr := encode_primitive_int(u16, size_of(u16), ptr, offset)
		buff_write(buffer, arr[:])
	case u32:
		buff_write_type(buffer, u32)
		arr := encode_primitive_int(u32, size_of(u32), ptr, offset)
		buff_write(buffer, arr[:])
	case u64:
		buff_write_type(buffer, u64)
		arr := encode_primitive_int(u64, size_of(u64), ptr, offset)
		buff_write(buffer, arr[:])
	case u128:
		buff_write_type(buffer, u128)
		arr := encode_primitive_int(u128, size_of(u128), ptr, offset)
		buff_write(buffer, arr[:])
	case uint:
		buff_write_type(buffer, uint)
		arr := encode_primitive_int(uint, size_of(uint), ptr, offset)
		buff_write(buffer, arr[:])
	case bool:
		buff_write_type(buffer, bool)
		arr := encode_primitive_int(bool, size_of(bool), ptr, offset)
		buff_write(buffer, arr[:])
	case rune:
		buff_write_type(buffer, rune)
		arr := encode_primitive_int(rune, size_of(rune), ptr, offset)
		buff_write(buffer, arr[:])
	}
	return nil
}


EncodeError :: union #shared_nil {
	Error,
	EncoderError,
}


// Encodes v into slice of bytes returns slize of bytes or error if any. 
//
// The encoded value slice contains [[type,size,...data]]
encode :: proc(
	enc: ^Encoder,
	v: any,
	alloc := context.allocator,
	loc := #caller_location,
) -> EncodeError {
	ti := runtime.type_info_base(type_info_of(v.id))
	buffer := buff_new(ti.size, alloc)


	//NOTE: is there a better way to do this ?
	#partial switch info in ti.variant {
	case runtime.Type_Info_Integer:
		encode_int(ti.id, &buffer, v.data)
	case runtime.Type_Info_Boolean:
		b := (^bool)(v.data)
		buff_write_type(&buffer, bool)
		bytes := bool_to_bytes(b^)
		buff_write(&buffer, bytes[:])
	// encode_int(ti.id, &buffer, v.data)
	case runtime.Type_Info_Rune:
		encode_int(ti.id, &buffer, v.data)
	case runtime.Type_Info_String:
		slice := encode_string(v.data)
		defer delete(slice)
		buff_write(&buffer, slice)
	case runtime.Type_Info_Struct:
		variant := ti.variant.(runtime.Type_Info_Struct)
	// encode_struct(variant, &buffer, ti.size, v.data)
	case:
		return Error.UnsupportedType
	}

	return enc->write(buff_read(&buffer))
}


// Default decoder function
decode :: proc(decoder: ^Decoder, dest: ..any) -> Error {

	if len(dest) == 0 {
		return Error.NoDestinations
	}

	if len(decoder.content) == 0 {
		return Error.EmptySlice
	}

	version := decoder.content[0]
	if version != VERSION {
		return Error.WrongVersion
	}

	size := decoder_size(decoder)

	if size == 0 {
		return Error.SizeZero
	}

	if len(dest) == 1 {
		type, bytes, e := decoder_read(decoder)
		if e != nil do return e
		_, readerr := read(bytes, dest[0], type, decoder.allocator)
		return readerr
	}


	for destination in dest {
		type, bytes, e := decoder_read(decoder)
		if e != nil do return e

		n, readerr := read(bytes, destination, type, decoder.allocator)
		if readerr != nil do return readerr
	}

	return nil
}


@(private)
// Reads from b(bytes) into v(value)
read :: proc(
	bytes: []byte,
	val: any,
	type: Type,
	alloc := context.allocator,
	loc := #caller_location,
) -> (
	int,
	Error,
) {
	read := 0

	#partial switch type {
	case .I8:
		r := read_into_int(bytes, val, i8)
		read += r
	case .I16:
		r := read_into_int(bytes, val, i16)
		read += r
	case .I32:
		r := read_into_int(bytes, val, i32)
		read += r
	case .I64:
		r := read_into_int(bytes, val, i64)
		read += r
	case .I128:
		r := read_into_int(bytes, val, i128)
		read += r
	case .Int:
		r := read_into_int(bytes, val, int)
		read += r
	case .U8:
		r := read_into_int(bytes, val, u8)
		read += r
	case .U16:
		r := read_into_int(bytes, val, u16)
		read += r
	case .U32:
		r := read_into_int(bytes, val, u32)
		read += r
	case .U64:
		r := read_into_int(bytes, val, u64)
		read += r
	case .U128:
		r := read_into_int(bytes, val, u128)
		read += r
	case .UInt:
		r := read_into_int(bytes, val, uint)
		read += r
	case .Boolean:
		r := read_into_int(bytes, val, bool)
		read += r
	case .String:
		length := bytes[0]
		read += 1
		// b = b[1:]
		s := (^string)(val.data)
		s^ = string(bytes[:length])
		read += cast(int)length
	case .Rune:
		r := read_into_int(bytes, val, rune)
		read += r
	case:
		return 0, Error.UnsupportedType
	}


	return read, nil
}

@(private)
// Reads from bytes into value. If [T] does not match type of value it panics
//
// Returns read bytes
read_into_int :: #force_inline proc(bytes: []byte, value: any, $T: typeid) -> int {
	assert(
		value.id == T,
		fmt.aprintf(
			"data type for v does not match source data type. expected %q got %q",
			type_info_of(value.id),
			type_info_of(T),
		),
	)

	read, number := btoi(bytes, size_of(T), T)
	dest := (^T)(value.data)
	dest^ = number
	return read
}
