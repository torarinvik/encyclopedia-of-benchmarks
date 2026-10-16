module problem22

const max_names = 6000
const max_name_length = 19
const max_input_length = 100001

fn compare_names(input &i64, offsets &int, name_lengths &int, first int, second int) int {
	first_length := unsafe { name_lengths[first] }
	second_length := unsafe { name_lengths[second] }
	shared_length := if first_length < second_length { first_length } else { second_length }
	for index in 0 .. shared_length {
		first_letter := unsafe { input[offsets[first] + index] }
		second_letter := unsafe { input[offsets[second] + index] }
		if first_letter < second_letter { return -1 }
		if first_letter > second_letter { return 1 }
	}
	if first_length < second_length { return -1 }
	if first_length > second_length { return 1 }
	return 0
}

@[export: 'problem22']
pub fn problem22(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input_length { return -1 }
	raw_count := unsafe { input[0] }
	if raw_count < 0 || raw_count > max_names { return -1 }
	count := int(raw_count)
	mut offsets := [max_names]int{}
	mut name_lengths := [max_names]int{}
	mut order := [max_names]int{}
	mut cursor := 1
	for name in 0 .. count {
		if cursor >= int(length) { return -1 }
		raw_name_length := unsafe { input[cursor] }
		cursor++
		if raw_name_length < 1 || raw_name_length > max_name_length { return -1 }
		name_length := int(raw_name_length)
		if name_length > int(length) - cursor { return -1 }
		offsets[name] = cursor
		name_lengths[name] = name_length
		for letter in 0 .. name_length {
			value := unsafe { input[cursor + letter] }
			if value < 1 || value > 26 { return -1 }
		}
		cursor += name_length
		order[name] = name
	}
	if cursor != int(length) { return -1 }

	gaps := [8]int{701, 301, 132, 57, 23, 10, 4, 1}
	for gap in gaps {
		if gap >= count { continue }
		for index := gap; index < count; index++ {
			key := order[index]
			mut position := index
			for position >= gap && compare_names(input, &offsets[0], &name_lengths[0], order[position - gap], key) > 0 {
				order[position] = order[position - gap]
				position -= gap
			}
			order[position] = key
		}
	}

	mut total := i64(0)
	for position in 0 .. count {
		name := order[position]
		mut score := i64(0)
		for letter in 0 .. name_lengths[name] {
			score += unsafe { input[offsets[name] + letter] }
		}
		total += i64(position + 1) * score
	}
	return total
}
