package all_threes_sequence

@(export, link_name="all_threes_sequence")
all_threes_sequence :: proc(index: i64) -> i64 {
	if index < 0 do return -1
	return 3
}

main :: proc() {}
