module main

const max_text = 32
const max_input_length = 67

fn longest_match(input &i64, first_base int, second_base int,
                 a0 int, a1 int, b0 int, b1 int) i64 {
	mut dp := []i64{len: 33}
	width := b1 - b0
	mut best_length := 0
	mut best_a := 0
	mut best_b := 0
	unsafe {
		for i := a0; i < a1; i++ {
			mut diagonal := i64(0)
			for column := 1; column <= width; column++ {
				old := dp[column]
				j := b0 + column - 1
				if input[first_base + i] == input[second_base + j] {
					current := int(diagonal) + 1
					dp[column] = i64(current)
					if current > best_length {
						best_length = current
						best_a = i + 1 - current
						best_b = j + 1 - current
					}
				} else { dp[column] = 0 }
				diagonal = old
			}
		}
	}
	return i64(best_length * 4096 + best_a * 64 + best_b)
}

fn matched_characters(input &i64, first_base int, second_base int,
					 a0 int, a1 int, b0 int, b1 int) i64 {
	if a0 >= a1 || b0 >= b1 { return 0 }
	packed := int(longest_match(input, first_base, second_base, a0, a1, b0, b1))
	block := packed / 4096
	if block == 0 { return 0 }
	rest := packed % 4096
	a := rest / 64
	b := rest % 64
	return i64(block) + matched_characters(input, first_base, second_base, a0, a, b0, b)
		+ matched_characters(input, first_base, second_base, a + block, a1, b + block, b1)
}

@[export: 'ratcliff_obershelp_similarity']
pub fn ratcliff_obershelp_similarity(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_length { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > i64(max_text) || input[1] < 0 || input[1] > i64(max_text) { return -1 }
		first_length := int(input[0])
		second_length := int(input[1])
		if length != usize(2 + first_length + second_length) { return -1 }
		for index in 0 .. first_length + second_length {
			byte := input[2 + index]
			if byte < 1 || byte > 127 { return -1 }
		}
		if first_length == 0 || second_length == 0 { return 0 }
		common := matched_characters(input, 2, 2 + first_length,
			0, first_length, 0, second_length)
		return (200 * common) / i64(first_length + second_length)
	}
}
