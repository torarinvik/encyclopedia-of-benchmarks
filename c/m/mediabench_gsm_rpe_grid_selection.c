#include <stddef.h>
#include <stdint.h>

#define INPUT_COUNT 40u
#define MAX_INPUT_LENGTH 41u
#define OUTPUT_BYTES 112u

static int64_t asr2(int64_t value)
{
    return value >= 0 ? value / 4 : -(((-value) + 3) / 4);
}

static void store_i64_le(uint8_t *out, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8u; ++byte) {
        out[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t mediabench_gsm_rpe_grid_selection(const int64_t *input, size_t input_length,
                                          uint8_t *output, size_t output_capacity)
{
    if (input == NULL || input_length == 0u || input_length > MAX_INPUT_LENGTH) return -1;
    for (size_t index = 0; index < input_length; ++index)
        if (input[index] < -32768 || input[index] > 32767) return -1;
    if (input_length != INPUT_COUNT) return -1;

    int64_t best_score = -1;
    int64_t best_grid = 0;
    for (int64_t grid = 0; grid < 4; ++grid) {
        int64_t sum = 0;
        for (int64_t i = 0; i < 13; ++i) {
            const int64_t scaled = asr2(input[grid + 3 * i]);
            sum += scaled * scaled;
        }
        const int64_t score = 2 * sum;
        if (score > best_score) { best_score = score; best_grid = grid; }
    }
    int64_t staged[14];
    staged[0] = best_grid;
    for (int64_t i = 0; i < 13; ++i) staged[1 + i] = input[best_grid + 3 * i];
    if (output == NULL || output_capacity < OUTPUT_BYTES) return -2;
    for (size_t index = 0; index < 14u; ++index) store_i64_le(output, 8u * index, staged[index]);
    return OUTPUT_BYTES;
}
