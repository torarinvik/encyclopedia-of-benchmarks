package main

@(export, link_name="cake_numbers_sequence")
cake_numbers_sequence :: proc(n: i64) -> i64 {
	if n < 0 || n > 2000000 do return -1
	return (n * n * n + 5 * n + 6) / 6
}

main :: proc() {}
