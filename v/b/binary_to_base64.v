module binary_to_base64

fn edge_space(value i64) bool { return (value >= 9 && value <= 13) || value == 32 }

@[export: 'binary_to_base64']
pub fn binary_to_base64(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > 256 { return -1 }
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
		for i := begin; i < end; i++ { if input[1 + i] != 48 && input[1 + i] != 49 { return -1 } }
		bit_count := end - begin
		padding := 6 - bit_count % 6
		groups := (bit_count + padding) / 6
		mut output_length := groups
		if negative { output_length++ }
		if capacity < usize(output_length) || output == nil { return -2 }
		alphabet := 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
		mut offset := 0
		if negative { output[offset] = u8('-'); offset++ }
		for group in 0 .. groups {
			mut value := 0
			for bit in 0 .. 6 {
				value <<= 1
				position := group * 6 + bit
				if position >= padding && input[1 + begin + position - padding] == 49 { value++ }
			}
			output[offset] = alphabet[value]
			offset++
		}
		return i64(output_length)
	}
}
