module single_number

// XOR reduction for the signed 32-bit single-number contract.
@[export: 'single_number']
pub fn single_number(values &i64, length usize) i64 {
	if length == 0 || length > 257 { return -2147483649 }
	mut bits := i64(0)
	for i in 0 .. length {
		value := unsafe { values[i] }
		if value < -2147483648 || value > 2147483647 { return -2147483649 }
		mut word := value
		if word < 0 { word += 4294967296 }
		bits = bits ^ word
	}
	if bits > 2147483647 { return bits - 4294967296 }
	return bits
}
