module reverse_array

@[export: 'reverse_array']
pub fn reverse_array(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if length < 1 || length > 257 { return -1 }
	count := input[0]
	if count < 1 || count > 256 || length != usize(count + 1) { return -1 }
	for i in 0 .. int(count) { if input[i + 1] < 0 || input[i + 1] > 255 { return -1 } }
	if capacity < usize(count) { return -2 }
	for i in 0 .. int(count) { output[i] = u8(input[i + 1]) }
	mut left := 0
	mut right := int(count) - 1
	for left < right { output[left], output[right] = output[right], output[left]; left++; right-- }
	return count
}
