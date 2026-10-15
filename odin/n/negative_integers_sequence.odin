package negative_integers_sequence

@(export, link_name="negative_integers_sequence")
negative_integers_sequence :: proc(index: i64) -> i64 {
	if index < 0 do return 0
	return -index - 1
}

main :: proc() {}
