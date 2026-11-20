module gray_code_k_combinations

@[export: 'gray_code_k_combinations']
pub fn gray_code_k_combinations(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length != 2 { return -1 }
	n_value, k_value := unsafe { input[0] }, unsafe { input[1] }
	if n_value < 0 || n_value > 12 || k_value < 0 || k_value > n_value { return -1 }
	n, k := int(n_value), int(k_value)
	mut smaller := k
	if smaller > n-k { smaller = n-k }
	mut count := 1
	for factor := 1; factor <= smaller; factor++ {
		count = count * (n-smaller+factor) / factor
	}
	required := 2 + 2 * count
	if unsafe { output == nil } || capacity < usize(required) { return -2 }
	unsafe {
		output[0] = u8(count & 255)
		output[1] = u8((count >> 8) & 255)
	}
	mut emitted := 0
	for index in 0 .. (1 << n) {
		mask := index ^ (index >> 1)
		mut remaining := mask
		mut population := 0
		for remaining > 0 {
			remaining &= remaining - 1
			population++
		}
		if population == k {
			unsafe {
				output[2 + 2 * emitted] = u8(mask & 255)
				output[3 + 2 * emitted] = u8((mask >> 8) & 255)
			}
			emitted++
		}
	}
	return i64(count)
}
