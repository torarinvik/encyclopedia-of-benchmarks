/*
 * Independent bounded port of the GSM RPE grid-positioning operation.
 * Source attribution and redistribution notice:
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
#include <stddef.h>
#include <stdint.h>

#define INPUT_COUNT 14u
#define MAX_INPUT_LENGTH 15u
#define OUTPUT_COUNT 40u
#define OUTPUT_BYTES (OUTPUT_COUNT * 2u)

static void store_i16_le(uint8_t *output, size_t offset, int64_t value)
{
    uint16_t bits = (uint16_t)value;
    output[offset] = (uint8_t)(bits & UINT16_C(255));
    output[offset + 1u] = (uint8_t)(bits >> 8);
}

int64_t mediabench_gsm_rpe_grid_positioning(const int64_t *input, size_t input_length,
                                             uint8_t *output, size_t output_capacity)
{
    if (input == NULL || input_length == 0u || input_length > MAX_INPUT_LENGTH) return -1;
    if (input_length != INPUT_COUNT) return -1;
    if (input[0] < 0 || input[0] > 3) return -1;
    for (size_t index = 1; index < INPUT_COUNT; ++index)
        if (input[index] < -32768 || input[index] > 32767) return -1;

    int64_t staged[OUTPUT_COUNT] = {0};
    for (size_t index = 0; index < 13u; ++index)
        staged[(size_t)input[0] + 3u * index] = input[index + 1u];
    if (output == NULL || output_capacity < OUTPUT_BYTES) return -2;
    for (size_t index = 0; index < OUTPUT_COUNT; ++index)
        store_i16_le(output, 2u * index, staged[index]);
    return OUTPUT_BYTES;
}
