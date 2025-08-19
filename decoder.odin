package binario


import "core:log"
import "core:mem"

decoder_fn :: proc(d: ^Decoder, dest: ..any) -> Error

DATA_START_POSITION: int : 5

Decoder :: struct {
	decode:    decoder_fn,
	content:   []byte,
	read_pos:  int,
	allocator: mem.Allocator,
}


// Creates a new decoder
decoder_new :: proc(bytes: []byte, alloc := context.allocator) -> Decoder {
	return Decoder {
		content = bytes,
		decode = decode,
		read_pos = DATA_START_POSITION,
		allocator = alloc,
	}
}


decoder_size :: proc(dec: ^Decoder) -> u32 {
	bytes := dec.content[1:5]
	_, size := btoi(bytes, size_of(u32), u32)
	return size
}


// Reads decoder content returns type and bytes
decoder_read :: proc(dec: ^Decoder, alloc := context.allocator) -> (Type, []byte, Error) {
	if dec.read_pos >= len(dec.content) {
		return Type.EOF, nil, Error.EOF
	}

	type := dec.content[dec.read_pos]
	size := dec.content[dec.read_pos + 1]
	dec.read_pos += 2
	bytes := dec.content[dec.read_pos:int(size) + dec.read_pos]

	return Type(type), bytes, nil
}
