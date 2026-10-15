module alaw

@[export: 'alaw_encode']
pub fn alaw_encode(input i64) i64 {
	if input < -32768 || input > 32767 { return -1 }
	sample := int(input)
	sign := if sample < 0 { 0x80 } else { 0 }
	magnitude := if sample < 0 { -sample - 1 } else { sample }
	mut segment := 7
	mut mask := 0x4000
	for (magnitude & mask) == 0 && segment > 0 {
		segment--
		mask >>= 1
	}
	shift := if segment != 0 { segment + 3 } else { 4 }
	quantization := (magnitude >> shift) & 0x0f
	return i64((sign | (segment << 4) | quantization) ^ 0xD5)
}
