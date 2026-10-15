module arithmetic_decoding

// Decode an exact arithmetic-coded lower-bound numerator.
@[export: 'arithmetic_decoding']
pub fn arithmetic_decoding(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 5 { return -1 }
	count := unsafe { input[0] }
	alphabet_size := unsafe { input[1] }
	if count < 1 || count > 12 || alphabet_size < 1 || alphabet_size > count
		|| length != usize(3 + 2 * alphabet_size) { return -1 }

	mut denominator := i64(1)
	for _ in 0 .. int(count) { denominator *= count }
	code := unsafe { input[2] }
	if code < 0 || code >= denominator { return -1 }

	mut symbols := [12]i64{init: 0}
	mut cumulative := [13]i64{init: 0}
	mut total := i64(0)
	for index in 0 .. int(alphabet_size) {
		symbol := unsafe { input[3 + 2 * index] }
		frequency := unsafe { input[4 + 2 * index] }
		if symbol < 0 || symbol > 255 || frequency < 1 || frequency > count
			|| (index > 0 && symbol <= symbols[index - 1]) { return -1 }
		symbols[index] = symbol
		total += frequency
		cumulative[index + 1] = total
	}
	if total != count { return -1 }
	if capacity < usize(count) || unsafe { output == nil } { return -2 }

	mut low := i64(0)
	mut high := i64(1)
	mut scale := denominator / count
	for step in 0 .. int(count) {
		range := high - low
		base := low * count
		mut found := false
		for index in 0 .. int(alphabet_size) {
			symbol_low := base + range * cumulative[index]
			symbol_high := base + range * cumulative[index + 1]
			if code >= symbol_low * scale && code < symbol_high * scale {
				unsafe { output[step] = u8(symbols[index]) }
				low = symbol_low
				high = symbol_high
				found = true
				break
			}
		}
		if !found { return -1 }
		if step + 1 < int(count) { scale /= count }
	}
	return count
}
