package tetrahedral_sequence

MAX_INDEX :: i64(3810777)

@(export, link_name="tetrahedral_sequence")
tetrahedral_sequence :: proc(index: i64) -> i64 {
	if index < 0 || index > MAX_INDEX do return -1
	a := index
	b := index + 1
	c := index + 2
	if a % 2 == 0 do a /= 2
	else if b % 2 == 0 do b /= 2
	else c /= 2
	if a % 3 == 0 do a /= 3
	else if b % 3 == 0 do b /= 3
	else c /= 3
	return a * b * c
}

main :: proc() {}
