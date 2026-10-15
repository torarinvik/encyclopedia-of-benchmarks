package natural_sequence

@(export, link_name="natural_sequence")
natural_sequence :: proc(index: i64) -> i64 {
	if index < 0 || index == i64(9223372036854775807) do return -1
	return index + 1
}

main :: proc() {}
