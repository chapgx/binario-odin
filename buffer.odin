package binario


Buff :: struct {
	content: [dynamic]byte,
	offset:  int,
}


// Returns the part of the buffer that has been written
buff_to_bytes :: proc(buff: ^Buff) -> []byte {
	return buff.content[:buff.offset]
}


// Returns the part of the buffer that has been written. This actions erases the written data
buff_read :: proc(buff: ^Buff) -> []byte {
	bytes := buff.content[:buff.offset]
	buff.offset = 0
	return bytes
}


// Calculates allocation size of v
buff_calc_size :: proc(v: any) -> int {return size_of(v.id) * 4}


// Creates a new [Buff]. It allocates memory
buff_new :: proc(size: int, alloc := context.allocator) -> Buff {
	b := Buff {
		offset = 2,
	}
	b.content = make([dynamic]byte, size * 4, alloc)
	return b
}


buff_write :: proc {
	write_bytes_and_type,
	write_bytes,
	buff_write_type,
}


write_size :: proc(buff: ^Buff, size: u8) -> Error {
	buff.content[1] = size
	return nil
}


buff_write_type :: proc(buff: ^Buff, $T: typeid) -> Error {
	type := typetoe(T)
	size := size_of(T)

	buff.content[0] = cast(u8)(type)
	buff.content[1] = u8(size)
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

	buff.content[0] = cast(u8)type

	copy(buff.content[buff.offset:], b)
	buff.offset += len(b)
	return nil
}
