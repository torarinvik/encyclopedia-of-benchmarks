module dna2_rna

@[export: 'dna2_rna']
pub fn dna2_rna(values &i64, length usize, output &mut u8, output_capacity usize) i64 {
	if length < 1 || length > 1001 { return -1 }
	if unsafe { values[0] } != 0 { return -1 }
	count := length - 1
	for index := usize(1); index < length; index++ {
		base := unsafe { values[index] }
		if base < 65 || base > 90 { return -1 }
	}
	if output_capacity < count { return -2 }
	for index := usize(0); index < count; index++ {
		base := unsafe { values[index + 1] }
		transcribed := if base == 84 { u8(85) } else { u8(base) }
		unsafe { output[index] = transcribed }
	}
	return i64(count)
}
