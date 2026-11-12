#include <stddef.h>
#include <stdint.h>

#define MAX_ORDER 16
#define MAX_CYCLE_LENGTH 10000

static void fkm_generate(size_t position, size_t period, size_t order,
                         size_t alphabet, uint8_t *work, uint8_t *output,
                         size_t *emitted) {
    if (position > order) {
        if (order % period == 0) {
            for (size_t index = 1; index <= period; ++index)
                output[(*emitted)++] = (uint8_t)('0' + work[index]);
        }
        return;
    }
    work[position] = work[position - period];
    fkm_generate(position + 1, period, order, alphabet, work, output, emitted);
    for (size_t symbol = (size_t)work[position - period] + 1; symbol < alphabet; ++symbol) {
        work[position] = (uint8_t)symbol;
        fkm_generate(position + 1, position, order, alphabet, work, output, emitted);
    }
}

int64_t de_bruijn_sequences(const int64_t *input, size_t length,
                            uint8_t *output, size_t capacity) {
    if (input == NULL || length != 2) return -1;
    const int64_t alphabet_value = input[0];
    const int64_t order_value = input[1];
    if (alphabet_value < 2 || alphabet_value > 10 || order_value < 1 || order_value > MAX_ORDER) return -1;
    const size_t alphabet = (size_t)alphabet_value;
    const size_t order = (size_t)order_value;
    size_t cycle_length = 1;
    for (size_t step = 0; step < order; ++step) {
        if (cycle_length > MAX_CYCLE_LENGTH / alphabet) return -1;
        cycle_length *= alphabet;
    }
    const size_t output_length = cycle_length + order - 1;
    if (capacity < output_length || output == NULL) return -2;

    uint8_t work[MAX_ORDER + 1] = {0};
    size_t emitted = 0;
    fkm_generate(1, 1, order, alphabet, work, output, &emitted);
    for (size_t index = 0; index + 1 < order; ++index)
        output[cycle_length + index] = output[index];
    return (int64_t)output_length;
}
