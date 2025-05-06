package tests


import b "../../binario"
import "core:log"
import "core:testing"


@(test)
// Test primitives encoding and decodeing
test_primitives :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	y: i8
	test_int(t, y, 100)

	x: i16
	test_int(t, x, 1000)


	r: i32
	test_int(t, r, 100_000)


	a: i64
	test_int(t, a, 100_000_000)

	b: i128
	test_int(t, b, 200_000_000)

	c: int
	test_int(t, c, 500_000_000)
}

@(test)
test_primitives_ui :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	y: u8
	test_int(t, y, 100)

	x: u16
	test_int(t, x, 1000)

	r: u32
	test_int(t, r, 100_000)

	a: u64
	test_int(t, a, 100_000_000)

	bb: u128
	test_int(t, bb, 200_000_000)

	c: uint
	test_int(t, c, 500_000_000)


	//NOTE: testing boolean
	l := false
	lt: bool
	buff, e := b.encode(l)
	testing.expectf(t, e == nil, "[decoding %s] expects e to be nil got %s", type_info_of(bool), e)
	e = b.decode(buff, lt)
	testing.expectf(
		t,
		e == b.Error.EOF,
		"[decoding %s] expects e to be nil got %s",
		type_info_of(bool),
		e,
	)
	testing.expectf(t, l == lt, "[decoding %s] expect %b got %b", type_info_of(bool), l, lt)
}


@(test)
test_string :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	o := "hello world"
	d: string
	buff, e := b.encode(o)
	testing.expect(t, e == nil, "expects e to be nil when encoding string")
	log.infof("%v\n", buff)
	e = b.decode(buff, d)
	testing.expect(t, e == b.Error.EOF, "expects e to be EOF when decoding string")
	testing.expectf(t, o == d, "expected %q got %q", o, d)
}

test_int :: proc(t: ^testing.T, o: $T, $N: T, alloc := context.allocator) {
	o: T = N
	d: T
	buff, e := b.encode(o)

	testing.expectf(t, e == nil, "[decoding %s] expects e to be nil got %s", type_info_of(T), e)

	e = b.decode(buff, d)

	testing.expectf(
		t,
		e == b.Error.EOF,
		"[decoding %s] expects e to be nil got %s",
		type_info_of(T),
		e,
	)

	testing.expectf(t, o == d, "[decoding %s] expect %d got %d", type_info_of(T), o, d)
}
