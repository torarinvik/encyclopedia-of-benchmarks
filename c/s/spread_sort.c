/* Bounded Java Integer SpreadSort semantics with signed-i32 output. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 128
#define INSERTION_THRESHOLD 16
#define MAX_BUCKETS 8
#define BUCKET_STRIDE 128

static void spread_sort_segment(int32_t *values, size_t length)
{
    if (length < 2) return;

    if (length <= INSERTION_THRESHOLD) {
        for (size_t index = 1; index < length; ++index) {
            const int32_t key = values[index];
            size_t position = index;
            while (position > 0 && values[position - 1] > key) {
                values[position] = values[position - 1];
                --position;
            }
            values[position] = key;
        }
        return;
    }

    int32_t minimum = values[0];
    int32_t maximum = values[0];
    for (size_t index = 1; index < length; ++index) {
        if (values[index] < minimum) minimum = values[index];
        if (values[index] > maximum) maximum = values[index];
    }
    if (minimum == maximum) return;

    size_t bucket_count = length / INSERTION_THRESHOLD;
    if (bucket_count < 2) bucket_count = 2;
    const size_t middle_bucket = bucket_count / 2;
    int32_t bucket_values[MAX_BUCKETS][BUCKET_STRIDE];
    size_t bucket_sizes[MAX_BUCKETS] = {0};

    for (size_t index = 0; index < length; ++index) {
        const size_t bucket = values[index] == minimum ? 0 : middle_bucket;
        bucket_values[bucket][bucket_sizes[bucket]++] = values[index];
    }

    size_t written = 0;
    for (size_t bucket = 0; bucket < bucket_count; ++bucket) {
        if (bucket_sizes[bucket] == 0) continue;
        spread_sort_segment(bucket_values[bucket], bucket_sizes[bucket]);
        for (size_t index = 0; index < bucket_sizes[bucket]; ++index)
            values[written++] = bucket_values[bucket][index];
    }
}

int64_t spread_sort(const int64_t *input, size_t length, uint8_t *output, size_t capacity)
{
    if (input == NULL || length > MAX_LENGTH) return -1;

    int32_t values[MAX_LENGTH];
    for (size_t index = 0; index < length; ++index) {
        if (input[index] < INT32_MIN || input[index] > INT32_MAX) return -1;
        values[index] = (int32_t)input[index];
    }
    if (length == 0) return 0;

    const size_t output_bytes = length * 4;
    if (output == NULL || capacity < output_bytes) return -2;

    spread_sort_segment(values, length);
    for (size_t index = 0; index < length; ++index) {
        const uint32_t bits = (uint32_t)values[index];
        output[index * 4] = (uint8_t)(bits & 255);
        output[index * 4 + 1] = (uint8_t)((bits >> 8) & 255);
        output[index * 4 + 2] = (uint8_t)((bits >> 16) & 255);
        output[index * 4 + 3] = (uint8_t)((bits >> 24) & 255);
    }
    return (int64_t)output_bytes;
}
