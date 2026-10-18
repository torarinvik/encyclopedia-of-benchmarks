/* Replay bounded calls through a memoized fixed-arity integer callback. */
#include <stddef.h>
#include <stdint.h>

#define MIN_ARITY 0
#define MAX_ARITY 4
#define MAX_CALLS 64
#define MIN_ARGUMENT (-100)
#define MAX_ARGUMENT 100
#define MAX_VALID_INPUT_LENGTH (2 + MAX_ARITY * MAX_CALLS)
#define MAX_PARSEABLE_INPUT_LENGTH (MAX_VALID_INPUT_LENGTH + 1)
#define MAX_OUTPUT_BYTES (8 * (MAX_CALLS + 1))
#define ENCODING_BASE 201

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t memoize(const int64_t *input, size_t input_length,
                uint8_t *output, size_t output_capacity)
{
    if (input == NULL || input_length < 2 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < MIN_ARITY || input[0] > MAX_ARITY ||
        input[1] < 0 || input[1] > MAX_CALLS) return -1;

    const size_t arity = (size_t)input[0];
    const size_t call_count = (size_t)input[1];
    if (input_length != 2 + arity * call_count) return -1;
    for (size_t index = 2; index < input_length; ++index)
        if (input[index] < MIN_ARGUMENT || input[index] > MAX_ARGUMENT) return -1;

    uint8_t staged[MAX_OUTPUT_BYTES];
    int64_t cached_callback_results[MAX_CALLS];
    size_t miss_count = 0;
    for (size_t call = 0; call < call_count; ++call) {
        int64_t result = 0;
        for (size_t argument = 0; argument < arity; ++argument) {
            const int64_t value = input[2 + call * arity + argument];
            result = result * ENCODING_BASE + (value - MIN_ARGUMENT);
        }

        /* For this fixed arity the base-201 callback encoding is injective,
           so it also distinguishes exactly the source's JSON-array keys. */
        size_t prior = 0;
        while (prior < miss_count && cached_callback_results[prior] != result) ++prior;
        if (prior == miss_count) cached_callback_results[miss_count++] = result;
        store_i64_le(staged, call * 8, result);
    }

    const size_t output_bytes = 8 * (call_count + 1);
    store_i64_le(staged, call_count * 8, (int64_t)miss_count);
    if (output == NULL || output_capacity < output_bytes) return -2;
    for (size_t index = 0; index < output_bytes; ++index) output[index] = staged[index];
    return (int64_t)output_bytes;
}
