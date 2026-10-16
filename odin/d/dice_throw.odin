package dice_throw

import "core:c"

MAX_FACES :: 8
MAX_DICE :: 8
MAX_TARGET :: 64

@(export)
dice_throw :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length != 3 do return -1
	faces_value := values[0]
	dice_value := values[1]
	target_value := values[2]
	if faces_value < 1 || faces_value > MAX_FACES || dice_value < 1 || dice_value > MAX_DICE ||
		target_value < 0 || target_value > MAX_TARGET do return -1
	faces := int(faces_value)
	dice := int(dice_value)
	target := int(target_value)

	var table: [MAX_DICE + 1][MAX_TARGET + 1]i64
	for total := 1; total <= faces && total <= target; total += 1 do table[1][total] = 1
	for die := 2; die <= dice; die += 1 {
		for total := 1; total <= target; total += 1 {
			for face := 1; face < total && face <= faces; face += 1 {
				table[die][total] += table[die - 1][total - face]
			}
		}
	}
	return table[dice][target]
}
