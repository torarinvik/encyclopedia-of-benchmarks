module alaw_decode

@[export: 'alaw_decode']
pub fn alaw_decode(input i64) i64 {
	if input < 0 || input > 255 { return -1 }
	alaw := int(input) ^ 0xD5
	sign := alaw & 0x80
	segment := (alaw & 0x70) >> 4
	mut sample := ((alaw & 0x0F) << 4) | 8
	if segment != 0 { sample += 0x100 }
	shift := if segment > 1 { segment - 1 } else { 0 }
	sample <<= shift
	if sign != 0 { return i64(-sample) }
	return i64(sample)
}
