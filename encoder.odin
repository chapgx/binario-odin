package binario

import "core:fmt"
import "core:log"
import "core:mem"


BEGINING_OFFSET: uint : 5

EncoderWriteFn :: proc(enc: ^Encoder, bytes: []byte) -> EncoderError
EncoderReadFn :: proc(enc: ^Encoder, alloc := context.allocator) -> []byte

Encoder :: struct {
	content: [dynamic]byte,
	offset:  uint,
	write:   EncoderWriteFn,
	read:    EncoderReadFn,
}


EncoderError :: union {
	Error,
	mem.Allocator_Error,
}


encoder_write :: proc(enc: ^Encoder, bytes: []byte) -> EncoderError {
	if len(enc.content[enc.offset:]) < len(bytes) {
		//TODO: gorw instead of panic needs to be implemented
		panic("buffer overflow")
	}

	for b in bytes {
		enc.content[enc.offset] = b
		enc.offset += 1
	}

	return nil
}


// Creates a new encoded buffer where size is the predifine size of the buffer
encoder_new :: proc(size: u32 = 32, alloc := context.allocator) -> Encoder {
	size := size + META_BYTES_PADDING
	size = size * size // square the size to redice reallocation of dynamic array

	enc := Encoder {
		offset  = BEGINING_OFFSET,
		content = make([dynamic]byte, size, alloc),
		write   = encoder_write,
		read    = encoder_read,
	}
	enc.content[0] = VERSION
	encoder_set_size(enc.content[:], size)

	return enc
}


// Returns current encoder version
encoder_version :: proc(encoder: ^Encoder) -> u8 {
	return encoder.content[0]
}


// Returns the encoder size
encoder_size :: proc(enc: ^Encoder) -> i32 {
	buff := enc.content[1:5]
	_, val := btoi(enc.content[1:5], 4, i32)
	return val
}


// Reads the encoder contents into a slice of bytes if no content to be read returns nil
encoder_read :: proc(enc: ^Encoder, alloc := context.allocator) -> []byte {
	if enc.offset == BEGINING_OFFSET {
		// if as the beginning it means is empty
		return nil
	}

	content_view := enc.content[:enc.offset]
	bytes := make([]byte, len(content_view))
	copy(bytes, content_view)

	enc.offset = BEGINING_OFFSET
	encoder_set_size(bytes, u32(len(bytes)))

	return bytes
}


@(private)
// Takes the content of an encoder and sets the size value
encoder_set_size :: proc(content: []byte, size: u32) {
	size := size
	ptr := &size
	arr := itob(rawptr(ptr), 4)
	for v, i in arr {
		content[i + 1] = v
	}
}
