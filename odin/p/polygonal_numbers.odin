package polygonal_numbers

import "core:c"

@(export)
polygonal_numbers :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
	if length != 2 do return -1
	num := packed[0]
	sides := packed[1]
	if num < 0 || num > 100000000 || sides < 3 || sides > 64 do return -1
	square := num * num
	leading := (sides - 2) * square
	trailing := (sides - 4) * num
	return (leading - trailing) / 2
}
