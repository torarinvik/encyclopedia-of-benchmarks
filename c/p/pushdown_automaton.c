/* Recognize the bounded language (1|2)^n 0^n with a pushdown-style counter. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_BYTE_LENGTH = 256, MAX_INPUT_LENGTH = 257 };

int64_t pushdown_automaton(const int64_t *values, size_t length)
{
    if (values == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t byte_length = values[0];
    if (byte_length < 0 || byte_length > MAX_BYTE_LENGTH) return -1;
    const size_t count = (size_t)byte_length;
    if (length != count + 1) return -1;

    for (size_t index = 0; index < count; ++index)
        if (values[index + 1] < 48 || values[index + 1] > 50) return -1;

    if (count == 0 || count % 2 != 0) return 0;
    const size_t half = count / 2;
    for (size_t index = 0; index < half; ++index)
        if (values[index + 1] != 49 && values[index + 1] != 50) return 0;
    for (size_t index = half; index < count; ++index)
        if (values[index + 1] != 48) return 0;
    return 1;
}
