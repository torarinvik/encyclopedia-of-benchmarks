/* Return unique sorted zero-sum triplets using sort-and-two-pointers. */
#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 257
#define BYTES_PER_TRIPLET 12

static void sift_down(int64_t *values, size_t root, size_t end)
{
    while (root < end / 2) {
        size_t child = root * 2 + 1;
        if (child + 1 < end && values[child] < values[child + 1]) ++child;
        if (values[root] >= values[child]) break;
        int64_t temporary = values[root];
        values[root] = values[child];
        values[child] = temporary;
        root = child;
    }
}

static void heap_sort(int64_t *values, size_t length)
{
    for (size_t start = length / 2; start > 0; --start)
        sift_down(values, start - 1, length);
    for (size_t end = length; end > 1; --end) {
        int64_t temporary = values[0];
        values[0] = values[end - 1];
        values[end - 1] = temporary;
        sift_down(values, 0, end - 1);
    }
}

static void store_i32_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint32_t bits = (uint32_t)(int32_t)value;
    for (size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

static size_t enumerate_triplets(const int64_t *values, size_t length,
                                uint8_t *output, int write_output)
{
    size_t result_count = 0;
    for (size_t first = 0; first + 2 < length; ++first) {
        if (first != 0 && values[first] == values[first - 1]) continue;
        size_t left = first + 1, right = length - 1;
        while (left < right) {
            const int64_t sum = values[first] + values[left] + values[right];
            if (sum < 0) {
                ++left;
            } else if (sum > 0) {
                --right;
            } else {
                if (write_output) {
                    const size_t offset = result_count * BYTES_PER_TRIPLET;
                    store_i32_le(output, offset, values[first]);
                    store_i32_le(output, offset + 4, values[left]);
                    store_i32_le(output, offset + 8, values[right]);
                }
                ++result_count;
                ++left;
                --right;
                while (left < right && values[left] == values[left - 1]) ++left;
                while (left < right && values[right] == values[right + 1]) --right;
            }
        }
    }
    return result_count;
}

int64_t three_sum(const int64_t *input, size_t length,
                  uint8_t *output, size_t output_capacity)
{
    if (length > MAX_ITEMS || (length != 0 && input == NULL)) return -1;
    int64_t values[MAX_ITEMS];
    for (size_t index = 0; index < length; ++index) {
        if (input[index] < -100000 || input[index] > 100000) return -1;
        values[index] = input[index];
    }
    heap_sort(values, length);

    const size_t maximum_bytes =
        length < 2 ? 0 : (length * (length - 1) / 2) * BYTES_PER_TRIPLET;
    if (output_capacity < maximum_bytes || output == NULL) {
        const size_t needed = enumerate_triplets(values, length, NULL, 0) * BYTES_PER_TRIPLET;
        if (output_capacity < needed || (needed != 0 && output == NULL)) return -2;
    }
    return (int64_t)enumerate_triplets(values, length, output, output != NULL);
}
