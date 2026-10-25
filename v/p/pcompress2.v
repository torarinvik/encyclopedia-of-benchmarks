// Clean-room bounded pcompress2 compression pipeline.
const max_length = 32
const max_output = 8 + max_length * 16
const symbols = 257

struct Coder {
	mut:
	bytes &u8
	length int
	buffer u8
	bits_to_go int
	low u32
	high u32
	follow int
	char_to_index [256]int
	index_to_char [258]u8
	freq [258]int
	cum [258]int
}

fn rotation_less(input &u8, n int, left int, right int) bool {
	unsafe {
		for offset in 0 .. n {
			a := input[(left + offset) % n]
			b := input[(right + offset) % n]
			if a != b { return a < b }
		}
	}
	return left < right
}

fn (mut c Coder) output_bit(bit bool) {
	c.buffer >>= 1
	if bit { c.buffer |= 0x80 }
	c.bits_to_go--
	if c.bits_to_go == 0 {
		unsafe { c.bytes[c.length] = c.buffer }
		c.length++
		c.bits_to_go = 8
	}
}

fn (mut c Coder) bit_plus_follow(bit bool) {
	c.output_bit(bit)
	for c.follow > 0 { c.output_bit(!bit); c.follow-- }
}

fn (mut c Coder) encode_symbol(symbol int) {
	span := u64(c.high - c.low) + 1
	old_low := c.low
	c.high = old_low + u32(span * u64(c.cum[symbol - 1]) / u64(c.cum[0])) - 1
	c.low = old_low + u32(span * u64(c.cum[symbol]) / u64(c.cum[0]))
	for {
		if c.high < 32768 { c.bit_plus_follow(false) }
		else if c.low >= 32768 { c.bit_plus_follow(true); c.low -= 32768; c.high -= 32768 }
		else if c.low >= 16384 && c.high < 49152 { c.follow++; c.low -= 16384; c.high -= 16384 }
		else { break }
		c.low *= 2
		c.high = c.high * 2 + 1
	}
}

fn (mut c Coder) update_model(symbol int) {
	if c.cum[0] == 16383 {
		mut total := 0
		for i := symbols; i >= 0; i-- { c.freq[i] = (c.freq[i] + 1) / 2; c.cum[i] = total; total += c.freq[i] }
	}
	mut i := symbol
	for c.freq[i] == c.freq[i - 1] { i-- }
	if i < symbol {
		a := c.index_to_char[i]
		b := c.index_to_char[symbol]
		c.index_to_char[i] = b
		c.index_to_char[symbol] = a
		c.char_to_index[int(a)] = symbol
		c.char_to_index[int(b)] = i
	}
	c.freq[i]++
	for i > 0 { i--; c.cum[i]++ }
}

fn arithmetic_encode(data &u8, count int, mut encoded &u8) int {
	mut c := Coder{bytes: encoded, bits_to_go: 8, low: 0, high: 65535}
	for i in 0 .. 256 { c.char_to_index[i] = i + 1; c.index_to_char[i + 1] = u8(i) }
	for i in 0 .. 258 { c.freq[i] = 1; c.cum[i] = symbols - i }
	c.freq[0] = 0
	unsafe {
		for i in 0 .. count {
			symbol := c.char_to_index[int(data[i])]
			c.encode_symbol(symbol)
			c.update_model(symbol)
		}
	}
	c.encode_symbol(257)
	c.follow++
	c.bit_plus_follow(c.low >= 16384)
	unsafe { c.bytes[c.length] = u8(c.buffer >> u32(c.bits_to_go)) }
	c.length++
	return c.length
}

fn compress_bounded(input &u8, n int, mut output &u8) int {
	mut order := [max_length]usize{}
	mut last := [max_length]u8{}
	mut rle := [max_length * 2]u8{}
	mut rle_length := 0
	unsafe {
		for i in 0 .. n { order[i] = usize(i) }
		for i in 1 .. n {
			key := order[i]
			mut j := i
			for j > 0 && rotation_less(input, n, int(key), int(order[j - 1])) { order[j] = order[j - 1]; j-- }
			order[j] = key
		}
		mut primary := 0
		for row in 0 .. n { if order[row] == 0 { primary = row }; last[row] = input[(int(order[row]) + n - 1) % n] }
		mut i := 0
		for i < n {
			mut count := 1
			value := last[i]
			for i + count < n && last[i + count] == value && count < 127 { count++ }
			if count == 1 {
				for i + count < n && last[i + count - 1] != last[i + count] && (i + count + 1 == n || last[i + count] != last[i + count + 1]) { count++ }
				rle[rle_length] = u8(count & 0x7f); rle_length++
				for j in 0 .. count { rle[rle_length] = last[i + j]; rle_length++ }
				i += count
			} else { rle[rle_length] = u8(count | 0x80); rle_length++; rle[rle_length] = value; rle_length++; i += count }
		}
		output[0] = u8(n); output[1] = 0; output[2] = 0; output[3] = 0
		output[4] = u8(primary); output[5] = 0; output[6] = 0; output[7] = 0
	}
	mut payload := [max_output]u8{}
	payload_length := arithmetic_encode(&rle[0], rle_length, mut payload[0])
	unsafe { for i in 0 .. payload_length { output[8 + i] = payload[i] } }
	return 8 + payload_length
}

@[export: 'pcompress2']
pub fn pcompress2(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if values == nil || length < 2 { return -1 }
		if values[0] < 1 || values[0] > max_length { return -1 }
		n := int(values[0])
		if length != usize(n + 1) { return -1 }
		mut input := [max_length]u8{}
		for i in 0 .. n { if values[i + 1] < 0 || values[i + 1] > 255 { return -1 }; input[i] = u8(values[i + 1]) }
		mut encoded := [max_output]u8{}
		encoded_length := compress_bounded(&input[0], n, mut encoded[0])
		if output == nil || output_capacity < usize(encoded_length) { return -2 }
		for i in 0 .. encoded_length { output[i] = encoded[i] }
		return i64(encoded_length)
	}
}
