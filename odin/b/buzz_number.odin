package buzz_number

@(export)
buzz_number :: proc "c" (n: i64) -> i64 {
	if n % 7 == 0 do return 1
	if n >= 0 && n % 10 == 7 do return 1
	return 0
}
