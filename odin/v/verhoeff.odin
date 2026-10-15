package verhoeff

import "core:c"

D: [100]u8 = {
	0,1,2,3,4,5,6,7,8,9, 1,2,3,4,0,6,7,8,9,5,
	2,3,4,0,1,7,8,9,5,6, 3,4,0,1,2,8,9,5,6,7,
	4,0,1,2,3,9,5,6,7,8, 5,9,8,7,6,0,4,3,2,1,
	6,5,9,8,7,1,0,4,3,2, 7,6,5,9,8,2,1,0,4,3,
	8,7,6,5,9,3,2,1,0,4, 9,8,7,6,5,4,3,2,1,0,
}
P: [80]u8 = {
	0,1,2,3,4,5,6,7,8,9, 1,5,7,6,2,8,3,0,9,4,
	5,8,0,3,7,9,6,1,4,2, 8,9,1,6,0,4,3,5,2,7,
	9,4,5,3,1,2,6,8,7,0, 4,2,8,6,5,7,3,9,0,1,
	2,7,9,3,8,0,6,4,1,5, 7,0,4,6,9,1,3,2,5,8,
}

@(export)
verhoeff :: proc "c" (digits: [^]i64, length: c.size_t) -> i64 {
	if length == 0 || length > 1024 do return -1
	for i := c.size_t(0); i < length; i += 1 {
		if digits[i] < 0 || digits[i] > 9 do return -1
	}
	checksum: u8 = 0
	for i := c.size_t(0); i < length; i += 1 {
		digit := u8(digits[length - i - 1])
		permutation := P[int(i % 8) * 10 + int(digit)]
		checksum = D[int(checksum) * 10 + int(permutation)]
	}
	return if checksum == 0 { 1 } else { 0 }
}
