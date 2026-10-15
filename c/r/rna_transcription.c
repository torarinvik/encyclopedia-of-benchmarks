/* Transcribe a DNA strand into its complementary RNA bases. */
#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_VALUES 1001

int64_t rna_transcription(const int64_t *values, size_t length,
                          uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 1 || length > MAX_INPUT_VALUES || values[0] != 0) return -1;
    const size_t count = length - 1;
    for (size_t index = 1; index < length; ++index) {
        const int64_t base = values[index];
        if (base != 'A' && base != 'C' && base != 'G' && base != 'T') return -1;
    }
    if (output_capacity < count || (count != 0 && output == NULL)) return -2;
    for (size_t index = 0; index < count; ++index) {
        switch (values[index + 1]) {
        case 'A': output[index] = 'U'; break;
        case 'C': output[index] = 'G'; break;
        case 'G': output[index] = 'C'; break;
        default:  output[index] = 'A'; break; /* T */
        }
    }
    return (int64_t)count;
}
