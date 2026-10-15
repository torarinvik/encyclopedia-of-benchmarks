package main

@(export, link_name="cubes_sequence")
cubes_sequence :: proc(index: i64) -> i64 {
	if index < 0 || index > 2097151 do return -1
	return index * index * index
}

main :: proc() {}
