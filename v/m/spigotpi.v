module spigotpi

const max_digits = 256
const max_boxes = 854

@[export: 'spigotpi']
pub fn spigotpi(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length != 1 || unsafe { input == nil } || unsafe { input[0] < 0 || input[0] > max_digits } {
		return -1
	}
	unsafe {
		digit_count := int(input[0])
		if output == nil || output_capacity < usize(digit_count) { return -2 }
		if digit_count == 0 { return 0 }

		boxes := digit_count * 10 / 3
		mut remainders := [max_boxes]i64{}
		for item in 0 .. boxes { remainders[item] = 2 }
		mut digits_held := 0
		for index in 0 .. digit_count {
			mut carried_over := i64(0)
			mut sum := i64(0)
			mut cursor := boxes
			for cursor > 0 {
				cursor--
				j := cursor
				remainders[j] *= 10
				sum = remainders[j] + carried_over
				denominator := i64(j * 2 + 1)
				quotient := sum / denominator
				remainders[j] = sum % denominator
				carried_over = quotient * i64(j)
			}
			remainders[0] = sum % 10
			mut q := sum / 10
			if q == 9 {
				digits_held++
			} else if q == 10 {
				q = 0
				for offset in 1 .. digits_held + 1 {
					position := index - offset
					if output[position] == `9` { output[position] = `0` } else { output[position]++ }
				}
				digits_held = 1
			} else {
				digits_held = 1
			}
			output[index] = u8(48 + q)
		}
		return i64(digit_count)
	}
}
