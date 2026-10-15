module reverse_words

@[export: 'reverse_words']
pub fn reverse_words(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length < 1 || unsafe { input == nil } { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > 256 { return -1 }
		n := int(input[0])
		if length != usize(n + 1) { return -1 }
		if output == nil || output_capacity < usize(n + 1) { return -2 }
		for i in 0 .. n {
			b := input[i + 1]
			if !(b == 32 || (b >= 33 && b <= 126)) { return -1 }
			if b == 32 && (i == 0 || i + 1 == n || input[i] == 32) { return -1 }
		}
		mut written := 0
		mut ending := n
		for ending > 0 {
			mut start := ending
			for start > 0 && input[start] != 32 { start-- }
			word_start := start
			for i in word_start .. ending { output[written] = u8(input[i + 1]); written++ }
			if word_start == 0 { break }
			output[written] = 32
			written++
			ending = start - 1
		}
		output[written] = 0
		return i64(written)
	}
}
