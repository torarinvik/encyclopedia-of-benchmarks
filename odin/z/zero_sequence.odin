package zero_sequence

@(export, link_name="zero_sequence")
zero_sequence :: proc(index: i64) -> i64 {
	if index < 0 do return -1
	return 0
}

main :: proc() {}
