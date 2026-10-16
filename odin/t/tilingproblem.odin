package tilingproblem

@(export, link_name="tilingproblem")
tilingproblem :: proc "c" (input: [^]i64, length: uint) -> i64 {
	if length != 1 || input[0] < 0 || input[0] > 91 do return -1
	previous, current: i64 = 1, 1
	for width: i64 = 2; width <= input[0]; width += 1 { next := previous + current; previous = current; current = next }
	return current
}

main :: proc() {}
