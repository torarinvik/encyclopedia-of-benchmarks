package main

@(export, link_name="matchstick_triangle_sequence")
matchstick_triangle_sequence :: proc(n: i64) -> i64 {
	if n < 0 || n > 1000000 do return -1
	return (n * (n + 2) * (2 * n + 1)) / 8
}

main :: proc() {}
