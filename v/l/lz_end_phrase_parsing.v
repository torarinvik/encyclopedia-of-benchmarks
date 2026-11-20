const max_text = 64
const max_input = 66
const phrase_multiplier = i64(133121)

@[export: 'lz_end_phrase_parsing']
pub fn lz_end_phrase_parsing(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_input { return -1 }
		n64 := input[0]
		if n64 < 0 || n64 > max_text || length != usize(n64 + 1) { return -1 }
		n := int(n64)
		for i in 0 .. n { if input[i + 1] < 0 || input[i + 1] > 255 { return -1 } }
		mut boundaries := [max_text]int{}
		mut phrase_lengths := [max_text]int{}
		mut phrases, mut position := 0, 0
		for position < n {
			mut best_copy := 0
			mut copy_length := n - position - 1
			for copy_length > 0 && best_copy == 0 {
				mut prior := phrases - 1
				for prior >= 0 && best_copy == 0 {
					boundary := boundaries[prior]
					if boundary >= copy_length {
						mut matches := true
						for offset in 0 .. copy_length {
							if input[1 + position + offset] != input[1 + boundary - copy_length + offset] { matches = false; break }
						}
						if matches { best_copy = copy_length }
					}
					prior--
				}
				copy_length--
			}
			phrase_lengths[phrases] = best_copy + 1
			position += phrase_lengths[phrases]
			boundaries[phrases] = position
			phrases++
		}
		mut checksum := i64(0)
		for i in 0 .. phrases { checksum += i64(i + 1) * i64(phrase_lengths[i]) }
		return phrase_multiplier * i64(phrases) + checksum
	}
}
