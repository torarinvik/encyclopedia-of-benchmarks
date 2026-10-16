/* Count contiguous runs of equal ASCII bytes. */
#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT_BYTES 4096

int64_t count_homogenous(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || input[0] < 0 || input[0] > MAX_TEXT_BYTES) return -1;
    const size_t count = (size_t)input[0];
    if (length != count + 1) return -1;
    for (size_t i = 0; i < count; ++i) {
        if (input[1 + i] < 0 || input[1 + i] > 127) return -1;
    }
    if (count == 0) return 0;
    size_t runs = 1;
    for (size_t i = 2; i <= count; ++i) {
        if (input[i] != input[i - 1]) ++runs;
    }
    return (int64_t)runs;
}
