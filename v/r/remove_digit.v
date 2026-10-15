module remove_digit

const invalid_result = i64(-1)
const min_valid_input = i64(-9_223_372_036_854_775_807)

@[export: 'remove_digit']
pub fn remove_digit(value i64) i64 {
	if value < min_valid_input { return invalid_result }
	mut magnitude := if value < 0 { -value } else { value }
	if magnitude < 10 { return invalid_result }
	mut top_place := i64(1)
	for top_place <= magnitude / 10 { top_place *= 10 }
	mut digit_count := i64(0)
	mut place := top_place
	for place > 0 {
		digit_count++
		place /= 10
	}
	mut maximum := i64(0)
	for removed in 0 .. int(digit_count) {
		mut candidate := i64(0)
		mut position := i64(0)
		place = top_place
		for place > 0 {
			digit := (magnitude / place) % 10
			if position != i64(removed) { candidate = candidate * 10 + digit }
			position++
			place /= 10
		}
		if candidate > maximum { maximum = candidate }
	}
	return maximum
}
