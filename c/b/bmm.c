#include <stddef.h>
#include <stdint.h>

/* Modified bounded-profile derivative; carry benchmarks/b/bmm/LICENSE with this source. */

#define MAX_SIZE 128u
#define SOURCE_SIZE 1024u
#define MAX_CELLS (MAX_SIZE * MAX_SIZE)
#define MAX_OUTPUT_BYTES 29u

static uint32_t next_random(uint32_t *state)
{
    *state = *state * UINT32_C(1664525) + UINT32_C(1013904223);
    return (*state >> 16) & UINT32_C(0x7fff);
}

static size_t append_unsigned(uint32_t value, uint8_t *staged, size_t used)
{
    uint8_t reverse[10];
    size_t count = 0;
    do {
        reverse[count++] = (uint8_t)('0' + value % 10u);
        value /= 10u;
    } while (value != 0u);
    while (count != 0u) staged[used++] = reverse[--count];
    return used;
}

int64_t versabench_bmm(const int64_t *input, size_t length,
                       uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length != 2u) return -1;
    if (input[0] < 1 || input[0] > (int64_t)MAX_SIZE ||
        input[1] < 1 || input[1] > input[0] || input[0] % input[1] != 0)
        return -1;

    const size_t size = (size_t)input[0];
    const size_t block = (size_t)input[1];
    float a[MAX_CELLS] = {0.0f};
    float b[MAX_CELLS] = {0.0f};
    float c[MAX_CELLS] = {0.0f};
    uint32_t seed = 1u;

    for (size_t i = 0; i < size; ++i) {
        for (size_t j = 0; j < SOURCE_SIZE; ++j) {
            const uint32_t random_a = next_random(&seed);
            const uint32_t random_b = next_random(&seed);
            if (j < size) {
                const uint32_t shift_a = ((uint32_t)(j & 31u) + 32u - (uint32_t)(i & 31u)) & 31u;
                const uint32_t shift_b = ((uint32_t)i + (uint32_t)j) & 31u;
                a[i * size + j] = (float)((random_a >> shift_a) & 15u);
                b[i * size + j] = (float)((random_b << shift_b) & 15u);
            }
        }
    }

    for (size_t outer_i = 0; outer_i < size; outer_i += block) {
        for (size_t outer_j = 0; outer_j < size; outer_j += block) {
            for (size_t outer_k = 0; outer_k < size; outer_k += block) {
                for (size_t i = outer_i; i < outer_i + block; ++i) {
                    for (size_t j = outer_j; j < outer_j + block; ++j) {
                        const size_t cell = i * size + j;
                        for (size_t k = outer_k; k < outer_k + block; ++k)
                            c[cell] += a[i * size + k] * b[k * size + j];
                    }
                }
            }
        }
    }

    float total = 0.0f;
    for (size_t outer_i = 0; outer_i < size; outer_i += block) {
        for (size_t outer_j = 0; outer_j < size; outer_j += block) {
            float subtotal = 0.0f;
            for (size_t i = outer_i; i < outer_i + block; ++i)
                for (size_t j = outer_j; j < outer_j + block; ++j)
                    subtotal += c[i * size + j];
            total += subtotal;
        }
    }

    uint8_t staged[MAX_OUTPUT_BYTES];
    size_t used = 0;
    static const uint8_t prefix[] = "final sum = ";
    for (size_t i = 0; i < sizeof(prefix) - 1u; ++i) staged[used++] = prefix[i];
    used = append_unsigned((uint32_t)total, staged, used);
    static const uint8_t suffix[] = ".000000\n";
    for (size_t i = 0; i < sizeof(suffix) - 1u; ++i) staged[used++] = suffix[i];

    if (output == NULL || output_capacity < used) return -2;
    for (size_t i = 0; i < used; ++i) output[i] = staged[i];
    return (int64_t)used;
}
