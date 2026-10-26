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

fn storeI16Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u16 = @truncate(@as(u64, @bitCast(value)));
    output[offset] = @truncate(bits);
    output[offset + 1] = @truncate(bits >> 8);
}

export fn mediabench_gsm_rpe_grid_positioning(
    input: ?[*]const i64, input_length: usize, output: ?[*]u8, output_capacity: usize,
) i64 {
    if (input == null or input_length == 0 or input_length > MAX_INPUT_LENGTH) return -1;
    const values = input.?[0..input_length];
    if (input_length != INPUT_COUNT or values[0] < 0 or values[0] > 3) return -1;
    for (values[1..]) |value| {
        if (value < -32768 or value > 32767) return -1;
    }

    var staged: [OUTPUT_COUNT]i64 = [_]i64{0} ** OUTPUT_COUNT;
    const grid: usize = @intCast(values[0]);
    for (0..13) |index| staged[grid + 3 * index] = values[index + 1];
    const out = output orelse return -2;
    if (output_capacity < OUTPUT_BYTES) return -2;
    for (0..OUTPUT_COUNT) |index| storeI16Le(out, 2 * index, staged[index]);
    return OUTPUT_BYTES;
}
