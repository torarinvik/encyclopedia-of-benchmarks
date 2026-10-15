/* Reverse a DNA sequence and complement each base. */
#include <stddef.h>
#include <stdint.h>

#define MAX_REVERSE_COMPLEMENT_LENGTH 1000

int64_t reverse_complement(const int64_t *input, size_t length,
                           uint8_t *output, size_t output_capacity)
{
    if (length > MAX_REVERSE_COMPLEMENT_LENGTH || (length != 0 && input == NULL)) return -1;
    for (size_t i = 0; i < length; ++i)
        if (input[i] != 'A' && input[i] != 'C' && input[i] != 'G' && input[i] != 'T') return -1;
    if (output_capacity < length || (length != 0 && output == NULL)) return -2;
    for (size_t i = 0; i < length; ++i) {
        const int64_t base = input[length - 1 - i];
        output[i] = (uint8_t)(base == 'A' ? 'T' : base == 'T' ? 'A' : base == 'C' ? 'G' : 'C');
    }
    return (int64_t)length;
}
