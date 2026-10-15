module hill_cipher_mod36

fn symbol_value(value i64) int {
	mut code := value
	if code >= 'a' && code <= 'z' { code -= 'a' - 'A' }
	if code >= 'A' && code <= 'Z' { return int(code - 'A') }
	if code >= '0' && code <= '9' { return int(code - '0') + 26 }
	return -1
}

fn output_symbol(value int) u8 {
	return if value < 26 { u8('A' + value) } else { u8('0' + value - 26) }
}

@[export: 'hill_cipher_mod36']
pub fn hill_cipher_mod36(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 3 { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > 1 { return -1 }
		raw_length := input[1]
		if raw_length < 1 || raw_length > 256 || length != usize(raw_length + 2) { return -1 }
		mut text := []int{cap: 256}
		for i in 0 .. int(raw_length) {
			byte := input[2+i]
			if byte < 0 || byte > 127 { return -1 }
			value := symbol_value(byte)
			if value >= 0 { text << value }
		}
		if text.len == 0 { return -1 }
		if text.len % 2 != 0 { text << text[text.len-1] }
		if output == nil || capacity < usize(text.len) { return -2 }
		decrypt := input[0] == 1
		for i := 0; i < text.len; i += 2 {
			a := text[i]; b := text[i+1]
			first := if decrypt { (6*a+25*b)%36 } else { (2*a+5*b)%36 }
			second := if decrypt { (5*a+26*b)%36 } else { (a+6*b)%36 }
			output[i] = output_symbol(first); output[i+1] = output_symbol(second)
		}
		return i64(text.len)
	}
}
