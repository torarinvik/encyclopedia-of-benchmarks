module base64_to_binary

fn edge_space(value i64) bool { return (value >= 9 && value <= 13) || value == 32 }
fn digit(value i64) int {
	if value >= 65 && value <= 90 { return int(value - 65) }
	if value >= 97 && value <= 122 { return int(value - 97 + 26) }
	if value >= 48 && value <= 57 { return int(value - 48 + 52) }
	if value == 43 { return 62 }
	if value == 47 { return 63 }
	return -1
}

@[export: 'base64_to_binary']
pub fn base64_to_binary(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > 256 { return -1 }
		n := int(input[0])
		if length != usize(n + 1) { return -1 }
		for i in 0 .. n { if input[1 + i] < 0 || input[1 + i] > 127 { return -1 } }
		mut begin := 0
		mut end := n
		for begin < end && edge_space(input[1 + begin]) { begin++ }
		for end > begin && edge_space(input[end]) { end-- }
		if begin == end { return -1 }
		negative := input[1 + begin] == 45
		if negative { begin++ }
		for i := begin; i < end; i++ { if digit(input[1 + i]) < 0 { return -1 } }
		output_length := (end - begin) * 6 + if negative { 1 } else { 0 }
		if capacity < usize(output_length) || output == nil { return -2 }
		mut offset := 0
		if negative { output[offset] = u8('-'); offset++ }
		for i := begin; i < end; i++ {
			value := u8(digit(input[1 + i]))
			for bit in 0 .. 6 { output[offset] = u8('0') + ((value >> (5 - bit)) & 1); offset++ }
		}
		return i64(output_length)
	}
}
