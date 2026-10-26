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
const INPUT_COUNT: usize = 14;
const MAX_INPUT_LENGTH: usize = 15;
const OUTPUT_COUNT: usize = 40;
const OUTPUT_BYTES: usize = 80;

fn store_i16_le(output: &mut [u8], offset: usize, value: i64) {
    let bits = value as u16;
    output[offset] = bits as u8;
    output[offset + 1] = (bits >> 8) as u8;
}

#[no_mangle]
pub unsafe extern "C" fn mediabench_gsm_rpe_grid_positioning(
    input: *const i64, input_length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length == 0 || input_length > MAX_INPUT_LENGTH { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, input_length) };
    if input_length != INPUT_COUNT || !(0..=3).contains(&values[0]) { return -1; }
    if values[1..].iter().any(|&value| !(-32768..=32767).contains(&value)) { return -1; }

    let mut staged = [0_i64; OUTPUT_COUNT];
    let grid = values[0] as usize;
    for index in 0..13 { staged[grid + 3 * index] = values[index + 1]; }
    if output.is_null() || output_capacity < OUTPUT_BYTES { return -2; }
    let out = unsafe { std::slice::from_raw_parts_mut(output, OUTPUT_BYTES) };
    for index in 0..OUTPUT_COUNT { store_i16_le(out, 2 * index, staged[index]); }
    OUTPUT_BYTES as i64
}
