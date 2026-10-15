module rna_transcription

const max_input_values = 1001

@[export: 'rna_transcription']
pub fn rna_transcription(values &i64, length usize, output &mut u8, output_capacity usize) i64 {
	if length < 1 || length > max_input_values { return -1 }
	if unsafe { values[0] } != 0 { return -1 }
	count := length - 1
	for index := usize(1); index < length; index++ {
		base := unsafe { values[index] }
		if base != 65 && base != 67 && base != 71 && base != 84 { return -1 }
	}
	if output_capacity < count { return -2 }
	for index := usize(0); index < count; index++ {
		base := unsafe { values[index + 1] }
		transcribed := if base == 65 { u8(85) } else if base == 67 { u8(71) } else if base == 71 { u8(67) } else { u8(65) }
		unsafe { output[index] = transcribed }
	}
	return i64(count)
}
