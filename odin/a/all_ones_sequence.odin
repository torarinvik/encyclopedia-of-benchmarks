package all_ones_sequence

@(export, link_name="all_ones_sequence")
all_ones_sequence :: proc(index: i64) -> i64 {
	if index < 0 do return -1
	return 1
}

main :: proc() {}
