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
module mediabench_gsm_rpe_grid_positioning

const input_count = 14
const max_input_length = 15
const output_count = 40
const output_bytes = 80

fn store_i16_le(mut output &u8, offset int, value i64) {
	bits := u16(value)
	output[offset] = u8(bits & 255)
	output[offset + 1] = u8(bits >> 8)
}

@[export: 'mediabench_gsm_rpe_grid_positioning']
pub fn mediabench_gsm_rpe_grid_positioning(input &i64, input_length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length == 0 || input_length > max_input_length { return -1 }
		if input_length != input_count || input[0] < 0 || input[0] > 3 { return -1 }
		for index in 1 .. input_count {
			if input[index] < -32768 || input[index] > 32767 { return -1 }
		}
		mut staged := [40]i64{}
		grid := int(input[0])
		for index in 0 .. 13 { staged[grid + 3 * index] = input[index + 1] }
		if output == nil || output_capacity < output_bytes { return -2 }
		for index in 0 .. output_count { store_i16_le(mut output, 2 * index, staged[index]) }
		return output_bytes
	}
}
