/* Port of TheAlgorithms/Python's 32-bit DJB2 hash on byte code points. */
#include <stddef.h>
#include <stdint.h>

#define MAX_BYTES 64
#define MAX_PARSED_BYTES 65

int64_t djb2(const int64_t *input, size_t length)
{
    if (length > MAX_PARSED_BYTES || (length > 0 && input == NULL)) return -1;
    if (length > MAX_BYTES) return -1;
    uint32_t hash = UINT32_C(5381);
    for (size_t index = 0; index < length; ++index) {
        const int64_t code_point = input[index];
        if (code_point < 0 || code_point > 255) return -1;
        hash = hash * UINT32_C(33) + (uint32_t)code_point;
    }
    return (int64_t)hash;
}
