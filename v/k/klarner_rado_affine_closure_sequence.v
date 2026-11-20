module klarner_rado_affine_closure_sequence

const max_index = i64(64)
const max_parseable_length = usize(2)

@[export: 'klarner_rado_affine_closure_sequence']
pub fn klarner_rado_affine_closure_sequence(input &i64, input_length usize) i64 {
	unsafe {
		if input == nil || input_length < 1 || input_length > max_parseable_length { return -1 }
		requested := input[0]
		if input_length != 1 || requested < 1 || requested > max_index { return -1 }

		mut terms := [64]i64{}
		terms[0] = 1
		mut count := 1
		mut twice := 0
		mut thrice_plus_two := 0
		mut sixfold_plus_three := 0
		for count < int(requested) {
			by_two := 2 * terms[twice]
			by_three := 3 * terms[thrice_plus_two] + 2
			by_six := 6 * terms[sixfold_plus_three] + 3
			mut next := by_two
			if by_three < next { next = by_three }
			if by_six < next { next = by_six }
			terms[count] = next
			count++
			if by_two == next { twice++ }
			if by_three == next { thrice_plus_two++ }
			if by_six == next { sixfold_plus_three++ }
		}
		return terms[int(requested) - 1]
	}
}
