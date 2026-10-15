/* Return the exact scaled lower bound produced by arithmetic coding. */
#include <stddef.h>
#include <stdint.h>

#define MAX_SYMBOLS 12
#define ALPHABET_SIZE 256

int64_t arithmetic_coding(const int64_t *input, size_t length)
{
    if (length < 2) return -1;
    const int64_t count = input[0];
    if (count < 1 || count > MAX_SYMBOLS || length != (size_t)(count + 1)) return -1;

    int64_t frequency[ALPHABET_SIZE] = {0};
    int64_t cumulative[ALPHABET_SIZE + 1] = {0};
    for (size_t index = 0; index < (size_t)count; ++index) {
        const int64_t symbol = input[index + 1];
        if (symbol < 0 || symbol >= ALPHABET_SIZE) return -1;
        ++frequency[symbol];
    }
    for (size_t symbol = 0; symbol < ALPHABET_SIZE; ++symbol)
        cumulative[symbol + 1] = cumulative[symbol] + frequency[symbol];

    int64_t low = 0;
    int64_t high = 1;
    for (size_t index = 0; index < (size_t)count; ++index) {
        const size_t symbol = (size_t)input[index + 1];
        const int64_t range = high - low;
        const int64_t base = low * count;
        high = base + range * cumulative[symbol + 1];
        low = base + range * cumulative[symbol];
    }
    return low;
}
