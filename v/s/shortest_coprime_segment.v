module shortest_coprime_segment

const max_length = 128

fn gcd_positive(a i64, b i64) i64 {
	mut left := a
	mut right := b
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

fn push(value i64, mut items &i64, mut aggregates &i64, mut length &usize) {
	unsafe {
		items[length[0]] = value
		aggregates[length[0]] = if length[0] == 0 { value } else { gcd_positive(aggregates[length[0] - 1], value) }
	}
	length[0]++
}

@[export: 'shortest_coprime_segment']
pub fn shortest_coprime_segment(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length > max_length { return -1 }
	unsafe {
		for i in 0 .. length { if input[i] < 1 || input[i] > 1000 { return -1 } }
		mut front := [max_length]i64{}
		mut front_gcd := [max_length]i64{}
		mut back := [max_length]i64{}
		mut back_gcd := [max_length]i64{}
		mut front_length := usize(0)
		mut back_length := usize(0)
		mut left := usize(0)
		mut best_start := usize(0)
		mut best_length := length + 1
		for right in 0 .. length {
			push(input[right], mut back[0], mut back_gcd[0], mut back_length)
			mut window_gcd := gcd_positive(if front_length > 0 { front_gcd[front_length - 1] } else { i64(0) },
				if back_length > 0 { back_gcd[back_length - 1] } else { i64(0) })
			for window_gcd == 1 {
				current_length := right - left + 1
				if current_length < best_length { best_length = current_length; best_start = left }
				if front_length == 0 {
					for back_length > 0 {
						back_length--
						push(back[back_length], mut front[0], mut front_gcd[0], mut front_length)
					}
				}
				front_length--
				left++
				window_gcd = gcd_positive(if front_length > 0 { front_gcd[front_length - 1] } else { i64(0) },
					if back_length > 0 { back_gcd[back_length - 1] } else { i64(0) })
			}
		}
		if best_length > length { return 0 }
		byte_count := best_length * 8
		if output_capacity < byte_count { return -2 }
		for i in 0 .. best_length {
			bits := u64(input[best_start + i])
			for byte in 0 .. 8 { output[8 * i + byte] = u8((bits >> (8 * byte)) & 255) }
		}
		return i64(byte_count)
	}
}
