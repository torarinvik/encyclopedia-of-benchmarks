/*
 * Independent bounded port of GSM RPE grid positioning.
 * Copyright 1992, 1993, 1994 by Jutta Degener and Carsten Bormann,
 * Technische Universitaet Berlin
 *
 * Any use of this software is permitted provided that this notice is not
 * removed and that neither the authors nor the Technische Universitaet Berlin
 * are deemed to have made any representations as to the suitability of this
 * software for any purpose nor are held responsible for any defects of this
 * software. THERE IS ABSOLUTELY NO WARRANTY FOR THIS SOFTWARE.
 * As a matter of courtesy, the authors request to be informed about uses
 * this software has found, about bugs in this software, and about any
 * improvements that may be of general interest.
 *
 * Berlin, 28.11.1994
 * Jutta Degener
 * Carsten Bormann
 */
package mediabench_gsm_rpe_grid_positioning

import "core:c"

INPUT_COUNT :: 14
MAX_INPUT_LENGTH :: c.size_t(15)
OUTPUT_COUNT :: 40
OUTPUT_BYTES :: 80

store_i16_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u16(value & 0xFFFF)
	output[offset] = u8(bits & 255)
	output[offset + 1] = u8(bits >> 8)
}

@(export)
mediabench_gsm_rpe_grid_positioning :: proc "c" (input: [^]i64, input_length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length == 0 || input_length > MAX_INPUT_LENGTH do return -1
	if input_length != c.size_t(INPUT_COUNT) || input[0] < 0 || input[0] > 3 do return -1
	for index := 1; index < INPUT_COUNT; index += 1 {
		if input[index] < -32768 || input[index] > 32767 do return -1
	}
	staged: [OUTPUT_COUNT]i64 = {}
	grid := int(input[0])
	for index := 0; index < 13; index += 1 { staged[grid + 3 * index] = input[index + 1] }
	if output == nil || output_capacity < c.size_t(OUTPUT_BYTES) do return -2
	for index := 0; index < OUTPUT_COUNT; index += 1 { store_i16_le(output, 2 * index, staged[index]) }
	return OUTPUT_BYTES
}
