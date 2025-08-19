package binario


Error :: enum {
	None,
	Full,
	EmptySlice,
	WrongVersion,
	SizeZero,
	EOF,
	UnsupportedType,
	AllocationError,
	NotAllItemsAppended,
	NoDestinations,
	BoolByteOutOfRange,
}
