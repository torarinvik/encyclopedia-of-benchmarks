package remove_digit

INVALID_RESULT :: i64(-1)
MIN_VALID_INPUT :: i64(-9_223_372_036_854_775_807)

@(export)
remove_digit :: proc "c" (value: i64) -> i64 {
	if value < MIN_VALID_INPUT do return INVALID_RESULT
	magnitude := if value < 0 { -value } else { value }
	if magnitude < 10 do return INVALID_RESULT
	top_place := i64(1)
	for top_place <= magnitude / 10 { top_place *= 10 }
	digit_count := i64(0)
	for place := top_place; place > 0; place /= 10 { digit_count += 1 }
	maximum := i64(0)
	for removed := i64(0); removed < digit_count; removed += 1 {
		candidate := i64(0)
		position := i64(0)
		for place := top_place; place > 0; place /= 10 {
			digit := (magnitude / place) % 10
			if position != removed { candidate = candidate * 10 + digit }
			position += 1
		}
		if candidate > maximum { maximum = candidate }
	}
	return maximum
}
