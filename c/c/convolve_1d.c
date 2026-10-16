#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_SIGNAL_LENGTH 64
#define MAX_INPUT_LENGTH (2 + 2 * MAX_SIGNAL_LENGTH)
#define MAX_OUTPUT_BYTES (MAX_SIGNAL_LENGTH * 8)
#define MAX_FIXED_SAMPLE 128
#define SAMPLE_SCALE 16.0

static void write_f64_le(uint8_t *output, size_t offset, double value)
{
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t convolve_1d(const int64_t *input, size_t length,
                    uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t raw_signal_count = input[0];
    const int64_t raw_kernel_count = input[1];
    if (raw_signal_count < 0 || raw_signal_count > MAX_SIGNAL_LENGTH ||
        raw_kernel_count < 0 || raw_kernel_count > MAX_SIGNAL_LENGTH) return -1;
    const size_t signal_count = (size_t)raw_signal_count;
    const size_t kernel_count = (size_t)raw_kernel_count;
    if (length != 2 + signal_count + kernel_count) return -1;
    for (size_t index = 0; index < signal_count + kernel_count; ++index) {
        if (input[index + 2] < -MAX_FIXED_SAMPLE || input[index + 2] > MAX_FIXED_SAMPLE) return -1;
    }

    const size_t output_bytes = signal_count * 8;
    if (output_capacity < output_bytes || (output_bytes > 0 && output == NULL)) return -2;
    const size_t center = kernel_count / 2;
    for (size_t i = 0; i < signal_count; ++i) {
        double accumulated = 0.0;
        for (size_t j = 0; j < kernel_count; ++j) {
            const int64_t raw_signal_index = (int64_t)i + (int64_t)j - (int64_t)center;
            if (raw_signal_index >= 0 && raw_signal_index < (int64_t)signal_count) {
                const double kernel_value = (double)input[2 + signal_count + j] / SAMPLE_SCALE;
                const double signal_value = (double)input[2 + (size_t)raw_signal_index] / SAMPLE_SCALE;
                accumulated += kernel_value * signal_value;
            }
        }
        write_f64_le(output, i * 8, accumulated);
    }
    return (int64_t)output_bytes;
}
