module count_and_say

const max_term_length = 256

@[export: 'count_and_say']
pub fn count_and_say(term_index i64, output &u8, output_capacity usize) i64 {
	if term_index < 1 || term_index > 19 { return -1 }
	mut current := [max_term_length]u8{}
	mut next := [max_term_length]u8{}
	mut current_length := usize(1)
	current[0] = u8(`1`)
	for term := i64(1); term < term_index; term++ {
		mut next_length := usize(0)
		mut index := usize(0)
		for index < current_length {
			mut ending := index + 1
			for ending < current_length && current[ending] == current[index] { ending++ }
			run_length := ending - index
			if next_length + 2 > max_term_length { return -1 }
			next[next_length] = u8(`0`) + u8(run_length)
			next[next_length + 1] = current[index]
			next_length += 2
			index = ending
		}
		for position := usize(0); position < next_length; position++ { current[position] = next[position] }
		current_length = next_length
	}
	unsafe {
		if output_capacity < current_length || output == nil { return -2 }
		for index := usize(0); index < current_length; index++ { output[index] = current[index] }
	}
	return i64(current_length)
}
