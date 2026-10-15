package squares_sequence

MAX_INDEX :: i64(3037000499)

@(export, link_name="squares_sequence")
squares_sequence :: proc(index: i64) -> i64 {
	if index < 0 || index > MAX_INDEX do return -1
	return index * index
}

main :: proc() {}
