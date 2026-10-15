module pythagorean_triple

// Check three signed integers with Java-compatible int-safe bounds.
@[export: 'pythagorean_triple']
pub fn pythagorean_triple(values &i64, length usize) i64 {
	if length != 3 { return -1 }
	mut a := unsafe { values[0] }
	mut b := unsafe { values[1] }
	mut c := unsafe { values[2] }
	if a < -32768 || a > 32767 || b < -32768 || b > 32767 || c < -32768 || c > 32767 { return -1 }
	if a <= 0 || b <= 0 || c <= 0 { return 0 }
	if a > b { temp := a; a = b; b = temp }
	if b > c { temp := b; b = c; c = temp }
	if a > b { temp := a; a = b; b = temp }
	if a * a + b * b == c * c { return 1 }
	return 0
}
