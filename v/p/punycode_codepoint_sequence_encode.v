module main

const max_points = 32
const max_words = 34
const max_output = 320

fn adapt_bias(initial_delta i64, point_count i64, first_time bool) i64 {
	mut delta := initial_delta / (if first_time { i64(700) } else { i64(2) })
	delta += delta / point_count
	mut k := i64(0)
	for delta > 455 {
		delta /= 35
		k += 36
	}
	return k + (36 * delta) / (delta + 38)
}

fn digit_byte(digit i64) u8 {
	if digit < 26 { return u8(97 + digit) }
	return u8(48 + digit - 26)
}

fn scalar(point i64) bool {
	return point >= 0 && point <= 0x10ffff && !(point >= 0xd800 && point <= 0xdfff)
}

@[export: 'punycode_codepoint_sequence_encode']
pub fn punycode_codepoint_sequence_encode(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_words { return -1 }
		count_word := input[0]
		if count_word < 0 || count_word > max_points || length != usize(count_word + 1) { return -1 }
		count := int(count_word)
		for index in 0 .. count {
			if !scalar(input[index + 1]) { return -1 }
		}
		mut staged := [max_output]u8{}
		mut basic_count := 0
		for index in 0 .. count {
			point := input[index + 1]
			if point < 0x80 {
				staged[basic_count] = u8(point)
				basic_count++
			}
		}
		mut written := basic_count
		if basic_count > 0 {
			staged[written] = `-`
			written++
		}
		mut n := i64(128)
		mut delta := i64(0)
		mut bias := i64(72)
		mut handled := basic_count
		for handled < count {
			mut minimum := i64(0x110000)
			for index in 0 .. count {
				point := input[index + 1]
				if point >= n && point < minimum { minimum = point }
			}
			delta += (minimum - n) * i64(handled + 1)
			n = minimum
			for index in 0 .. count {
				point := input[index + 1]
				if point < n { delta++ }
				if point == n {
					mut q := delta
					mut k := i64(36)
					for {
						mut threshold := i64(1)
						if k > bias { threshold = k - bias }
						if k >= bias + 26 { threshold = 26 }
						if q < threshold {
							staged[written] = digit_byte(q)
							written++
							break
						}
						staged[written] = digit_byte(threshold + (q - threshold) % (36 - threshold))
						written++
						q = (q - threshold) / (36 - threshold)
						k += 36
					}
				if handled == basic_count { delta /= 700 } else { delta /= 2 }
				delta += delta / i64(handled + 1)
				mut adapt_k := i64(0)
				for delta > 455 {
					delta /= 35
					adapt_k += 36
				}
				bias = adapt_k + (36 * delta) / (delta + 38)
				delta = 0
				handled++
			}
			delta++
			n++
		}
		if written > max_output { return -1 }
		if written > 0 {
			if output == nil || capacity < usize(written) { return -2 }
			for index in 0 .. written { output[index] = staged[index] }
		}
		return i64(written)
	}
}
