#include <stddef.h>
#include <stdint.h>

enum { MAX_SAMPLES = 32, MAX_ORDER = 4, MAX_INPUT_WORDS = 45 };

int64_t digital_filter_direct_form_ii_transposed(
    const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_WORDS) return -1;
    const int64_t sample_word = input[0];
    const int64_t order_word = input[1];
    if (sample_word < 0 || sample_word > MAX_SAMPLES ||
        order_word < 0 || order_word > MAX_ORDER) return -1;
    const size_t count = (size_t)sample_word;
    const size_t order = (size_t)order_word;
    if (length != count + 2 * order + 4) return -1;

    const size_t a_start = 2;
    const size_t b_start = order + 3;
    const size_t x_start = 2 * order + 4;
    if (input[a_start] != 1) return -1;
    for (size_t i = 1; i <= order; ++i)
        if (input[a_start + i] < -1 || input[a_start + i] > 1) return -1;
    for (size_t i = 0; i <= order; ++i)
        if (input[b_start + i] < -1 || input[b_start + i] > 1) return -1;
    for (size_t i = 0; i < count; ++i)
        if (input[x_start + i] < -16 || input[x_start + i] > 16) return -1;

    const size_t bytes = count * 8;
    if (bytes != 0 && (output == NULL || capacity < bytes)) return -2;
    if (count == 0) return 0;

    int64_t state[MAX_ORDER] = {0};
    for (size_t sample_index = 0; sample_index < count; ++sample_index) {
        const int64_t sample = input[x_start + sample_index];
        const int64_t value = input[b_start] * sample + (order == 0 ? 0 : state[0]);
        for (size_t stage = 0; stage < order; ++stage) {
            const int64_t next_state = stage + 1 < order ? state[stage + 1] : 0;
            state[stage] = next_state + input[b_start + stage + 1] * sample
                         - input[a_start + stage + 1] * value;
        }
        const uint64_t bits = (uint64_t)value;
        for (size_t byte = 0; byte < 8; ++byte)
            output[sample_index * 8 + byte] = (uint8_t)(bits >> (8 * byte));
    }
    return (int64_t)bytes;
}
