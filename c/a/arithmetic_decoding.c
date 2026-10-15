/* Decode an exact arithmetic-coded lower-bound numerator. */
#include <stddef.h>
#include <stdint.h>

#define MAX_SYMBOLS 12

int64_t arithmetic_decoding(const int64_t *input, size_t length,
                            uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 5) return -1;
    const int64_t count = input[0];
    const int64_t alphabet_size = input[1];
    if (count < 1 || count > MAX_SYMBOLS || alphabet_size < 1 || alphabet_size > count
        || length != (size_t)(3 + 2 * alphabet_size)) return -1;

    int64_t denominator = 1;
    for (int64_t index = 0; index < count; ++index) denominator *= count;
    const int64_t code = input[2];
    if (code < 0 || code >= denominator) return -1;

    int64_t symbols[MAX_SYMBOLS];
    int64_t cumulative[MAX_SYMBOLS + 1] = {0};
    int64_t total = 0;
    for (int64_t index = 0; index < alphabet_size; ++index) {
        const int64_t symbol = input[3 + 2 * index];
        const int64_t frequency = input[4 + 2 * index];
        if (symbol < 0 || symbol > 255 || frequency < 1 || frequency > count
            || (index > 0 && symbol <= symbols[index - 1])) return -1;
        symbols[index] = symbol;
        total += frequency;
        cumulative[index + 1] = total;
    }
    if (total != count) return -1;
    if (capacity < (size_t)count || output == NULL) return -2;

    int64_t low = 0;
    int64_t high = 1;
    int64_t scale = denominator / count;
    for (int64_t step = 0; step < count; ++step) {
        const int64_t range = high - low;
        const int64_t base = low * count;
        int found = 0;
        for (int64_t index = 0; index < alphabet_size; ++index) {
            const int64_t symbol_low = base + range * cumulative[index];
            const int64_t symbol_high = base + range * cumulative[index + 1];
            if (code >= symbol_low * scale && code < symbol_high * scale) {
                output[step] = (uint8_t)symbols[index];
                low = symbol_low;
                high = symbol_high;
                found = 1;
                break;
            }
        }
        if (!found) return -1;
        if (step + 1 < count) scale /= count;
    }
    return count;
}
