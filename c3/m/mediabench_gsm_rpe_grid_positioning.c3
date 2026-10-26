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
module mediabench_gsm_rpe_grid_positioning;

const usz INPUT_COUNT = 14;
const usz MAX_INPUT_LENGTH = 15;
const usz OUTPUT_COUNT = 40;
const usz OUTPUT_BYTES = 80;

fn void store_i16_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    output[offset] = (char)(bits & 255);
    output[offset + 1] = (char)((bits >> 8) & 255);
}

fn long mediabench_gsm_rpe_grid_positioning(long* input, usz input_length,
        char* output, usz output_capacity) @export("mediabench_gsm_rpe_grid_positioning")
{
    if (input == null || input_length == 0 || input_length > MAX_INPUT_LENGTH) return -1;
    if (input_length != INPUT_COUNT || input[0] < 0 || input[0] > 3) return -1;
    for (usz index = 1; index < INPUT_COUNT; index++)
        if (input[index] < -32768 || input[index] > 32767) return -1;

    long[40] staged = {0};
    for (usz index = 0; index < 13; index++)
        staged[(usz)input[0] + 3 * index] = input[index + 1];
    if (output == null || output_capacity < OUTPUT_BYTES) return -2;
    for (usz index = 0; index < OUTPUT_COUNT; index++)
        store_i16_le(output, 2 * index, staged[index]);
    return (long)OUTPUT_BYTES;
}
