package rna_transcription

import "core:c"

MAX_INPUT_VALUES :: 1001

@(export)
rna_transcription :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 1 || length > MAX_INPUT_VALUES || values[0] != 0 do return -1
	count := length - 1
	for index := c.size_t(1); index < length; index += 1 {
		base := values[index]
		if base != 'A' && base != 'C' && base != 'G' && base != 'T' do return -1
	}
	if output_capacity < count || (count > 0 && output == nil) do return -2
	for index := c.size_t(0); index < count; index += 1 {
		base := values[index + 1]
		if base == 'A' do output[index] = 'U'
		else if base == 'C' do output[index] = 'G'
		else if base == 'G' do output[index] = 'C'
		else do output[index] = 'A'
	}
	return i64(count)
}
