package all_twos_sequence

@(export, link_name="all_twos_sequence")
all_twos_sequence :: proc(index: i64) -> i64 {
	if index < 0 do return -1
	return 2
}

main :: proc() {}
