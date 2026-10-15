module arithmetic_coding

// Return the exact scaled lower bound produced by arithmetic coding.
@[export: 'arithmetic_coding']
pub fn arithmetic_coding(input &i64, length usize) i64 {
	if length < 2 { return -1 }
	count := unsafe { input[0] }
	if count < 1 || count > 12 || length != usize(count + 1) { return -1 }

	mut frequency := [256]i64{init: 0}
	mut cumulative := [257]i64{init: 0}
	for index in 0 .. int(count) {
		symbol := unsafe { input[index + 1] }
		if symbol < 0 || symbol > 255 { return -1 }
		frequency[int(symbol)]++
	}
	for symbol in 0 .. 256 {
		cumulative[symbol + 1] = cumulative[symbol] + frequency[symbol]
	}

	mut low := i64(0)
	mut high := i64(1)
	for index in 0 .. int(count) {
		symbol := int(unsafe { input[index + 1] })
		range := high - low
		base := low * count
		high = base + range * cumulative[symbol + 1]
		low = base + range * cumulative[symbol]
	}
	return low
}
