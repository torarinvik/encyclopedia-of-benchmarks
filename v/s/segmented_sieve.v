module segmented_sieve

fn put_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'segmented_sieve']
pub fn segmented_sieve(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length != 1 { return -1 }
	unsafe {
		if input[0] < 2 || input[0] > 10000 { return -1 }
		n := int(input[0])
		mut end := 0
		for (end + 1) * (end + 1) <= n { end++ }
		mut base_marks := [101]bool{init: false}
		mut base := [25]i64{}
		mut base_count := 0
		for i := 2; i <= end; i++ { base_marks[i] = true }
		for p := 2; p <= end; p++ {
			if !base_marks[p] { continue }
			base[base_count] = i64(p)
			base_count++
			mut multiple := p * p
			for multiple <= end { base_marks[multiple] = false; multiple += p }
		}
		mut primes := [1229]i64{}
		mut prime_count := 0
		for i in 0 .. base_count { primes[prime_count] = base[i]; prime_count++ }
		mut low := end + 1
		mut high := if 2 * end < n { 2 * end } else { n }
		for low <= n {
			mut segment := [201]bool{init: false}
			segment_length := high - low + 1
			for i in 0 .. segment_length { segment[i] = true }
			for i in 0 .. base_count {
				p := int(base[i])
				mut first := (low / p) * p
				if first < low { first += p }
				for first <= high { segment[first - low] = false; first += p }
			}
			for i in 0 .. segment_length {
				if segment[i] { primes[prime_count] = i64(low + i); prime_count++ }
			}
			low = high + 1
			high = if high + end < n { high + end } else { n }
		}
		output_length := prime_count * 8
		if capacity < usize(output_length) || (output_length > 0 && output == nil) { return -2 }
		for i in 0 .. prime_count { put_i64_le(mut output, i * 8, primes[i]) }
		return i64(output_length)
	}
}
