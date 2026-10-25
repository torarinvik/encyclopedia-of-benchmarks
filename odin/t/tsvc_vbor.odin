package tsvc_vbor

import "core:c"

MAX_N :: 128

@(export)
tsvc_vbor :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 7 || length > 1 + 6 * MAX_N do return -1
	n_value := values[0]
	if n_value < 1 || n_value > MAX_N do return -1
	n := int(n_value)
	if length != c.size_t(1 + 6 * n) do return -1
	for index := c.size_t(1); index < length; index += 1 {
		if values[index] < 0 || values[index] > 2 do return -1
	}

	checksum: i64 = 0
	for i := 0; i < n; i += 1 {
		a, b := values[1+i], values[1+n+i]
		cc, d := values[1+2*n+i], values[1+3*n+i]
		e, f := values[1+4*n+i], values[1+5*n+i]
		a1 := a*b*cc + a*b*d + a*b*e + a*b*f + a*cc*d + a*cc*e + a*cc*f + a*d*e + a*d*f + a*e*f
		b1 := b*cc*d + b*cc*e + b*cc*f + b*d*e + b*d*f + b*e*f
		c1 := cc*d*e + cc*d*f + cc*e*f
		d1 := d*e*f
		checksum += a1*b1*c1*d1
	}
	return checksum
}
