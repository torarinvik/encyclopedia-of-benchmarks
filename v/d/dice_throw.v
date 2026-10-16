module dice_throw

const max_faces = 8
const max_dice = 8
const max_target = 64

@[export: 'dice_throw']
pub fn dice_throw(values &i64, length usize) i64 {
	if unsafe { values == nil } || length != 3 { return -1 }
	faces_value := unsafe { values[0] }
	dice_value := unsafe { values[1] }
	target_value := unsafe { values[2] }
	if faces_value < 1 || faces_value > max_faces || dice_value < 1 || dice_value > max_dice ||
		target_value < 0 || target_value > max_target { return -1 }
	faces := int(faces_value)
	dice := int(dice_value)
	target := int(target_value)

	mut table := [max_dice + 1][max_target + 1]i64{}
	for total := 1; total <= faces && total <= target; total++ { table[1][total] = 1 }
	for die := 2; die <= dice; die++ {
		for total := 1; total <= target; total++ {
			for face := 1; face < total && face <= faces; face++ {
				table[die][total] += table[die - 1][total - face]
			}
		}
	}
	return table[dice][target]
}
