package alaw_decode

@(export)
alaw_decode :: proc "c" (input: i64) -> i64 {
	if input < 0 || input > 255 do return -1
	alaw := i32(input) ^ 0xD5
	sign := alaw & 0x80
	segment := (alaw & 0x70) >> 4
	sample := ((alaw & 0x0F) << 4) | 8
	if segment != 0 do sample += 0x100
	shift := 0
	if segment > 1 do shift = segment - 1
	sample <<= shift
	if sign != 0 do return i64(-sample)
	return i64(sample)
}
