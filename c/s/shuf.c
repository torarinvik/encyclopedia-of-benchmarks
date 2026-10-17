#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 67u
#define MAX_ITEMS 32u

static void write_i32_le(uint8_t *output, size_t offset, int32_t value)
{
    const uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4u; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8u));
}

int64_t shuf(const int64_t *input, size_t length,
             uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 2u || length > MAX_INPUT_LENGTH) return -1;
    const int64_t count_raw = input[0], sample_size_raw = input[1];
    if (count_raw < 0 || count_raw > 32 || sample_size_raw < 1 || sample_size_raw > 32) return -1;
    const size_t count = (size_t)count_raw, sample_size = (size_t)sample_size_raw;
    if (length != 2u + 2u * count) return -1;

    int32_t items[MAX_ITEMS], sample[MAX_ITEMS];
    uint8_t occupied[MAX_ITEMS] = {0};
    for (size_t index = 0; index < count; ++index) {
        const int64_t value = input[2u + index];
        if (value < INT32_MIN || value > INT32_MAX) return -1;
        items[index] = (int32_t)value;
    }

    const size_t initial_count = count < sample_size ? count : sample_size;
    for (size_t index = 0; index < initial_count; ++index) {
        const int64_t draw = input[2u + count + index];
        if (draw < 0 || (uint64_t)draw >= sample_size) return -1;
        size_t slot = (size_t)draw;
        while (occupied[slot] != 0u) {
            slot = (slot + 1u) % sample_size;
        }
        sample[slot] = items[index];
        occupied[slot] = 1u;
    }

    if (count >= sample_size) {
        for (size_t index = sample_size; index < count; ++index) {
            const int64_t draw = input[2u + count + index];
            if (draw < 0 || (uint64_t)draw > index) return -1;
            if ((size_t)draw < sample_size) sample[(size_t)draw] = items[index];
        }
    }

    size_t result_count = 0u;
    const size_t output_bytes = (count < sample_size ? count : sample_size) * 4u;
    if (output == NULL || output_capacity < output_bytes) return -2;
    for (size_t slot = 0; slot < sample_size; ++slot) {
        if (occupied[slot] != 0u) write_i32_le(output, result_count++ * 4u, sample[slot]);
    }
    return (int64_t)result_count;
}
