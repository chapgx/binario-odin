package binario

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


	//ENCODER TYPES


	//ERROR
	Unsupported,
	EOF,


	//TODO: expand to account for odin specific primitive types like i32be, i32le or complex32 and quaternion64
}


// Returns the enum encoded type of the typeid passed in
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
