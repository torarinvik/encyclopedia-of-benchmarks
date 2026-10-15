package adler32

import "core:c"

MAX_LENGTH :: 100_001
ADLER_MOD :: i64(65_521)

// Compute the standard Adler-32 checksum of byte values in the input array.
@(export)
adler32 :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length > MAX_LENGTH || (length != 0 && values == nil) do return -1
	a := i64(1)
	b := i64(0)
	for index := c.size_t(0); index < length; index += 1 {
		value := values[index]
		if value < 0 || value > 255 do return -1
		a = (a + value) % ADLER_MOD
		b = (b + a) % ADLER_MOD
	}
	return (b << 16) | a
}
