module adler32

const max_length = 100001
const adler_mod = i64(65521)

// Compute the standard Adler-32 checksum of byte values in the input array.
@[export: 'adler32']
pub fn adler32(values &i64, length usize) i64 {
	if length > max_length || (length != 0 && values == nil) { return -1 }
	mut a := i64(1)
	mut b := i64(0)
	for index in 0 .. length {
		value := unsafe { values[index] }
		if value < 0 || value > 255 { return -1 }
		a = (a + value) % adler_mod
		b = (b + a) % adler_mod
	}
	return (b << 16) | a
}
