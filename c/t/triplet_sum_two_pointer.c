#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 1024

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

static void sift_down(int64_t *values, size_t root, size_t end) {
    while (root < end / 2) {
        size_t child = root * 2 + 1;
        if (child + 1 < end && values[child] < values[child + 1]) ++child;
        if (values[root] >= values[child]) break;
        const int64_t temporary = values[root];
        values[root] = values[child];
        values[child] = temporary;
        root = child;
    }
}

static void heap_sort(int64_t *values, size_t length) {
    for (size_t start = length / 2; start > 0; --start) sift_down(values, start - 1, length);
    for (size_t end = length; end > 1; --end) {
        const int64_t temporary = values[0];
        values[0] = values[end - 1];
        values[end - 1] = temporary;
        sift_down(values, 0, end - 1);
    }
}

int64_t triplet_sum_two_pointer(const int64_t *input, size_t length,
                                uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 1 || length > MAX_ITEMS + 1 ||
        input[0] < -3000000 || input[0] > 3000000) return -1;
    const size_t item_count = length - 1;
    int64_t values[MAX_ITEMS];
    for (size_t index = 0; index < item_count; ++index) {
        if (input[index + 1] < -1000000 || input[index + 1] > 1000000) return -1;
        values[index] = input[index + 1];
    }
    if (output_capacity < 24 || output == NULL) return -2;
    heap_sort(values, item_count);

    int64_t result[3] = {0, 0, 0};
    for (size_t first = 0; first + 2 < item_count; ++first) {
        size_t left = first + 1, right = item_count - 1;
        while (left < right) {
            const int64_t sum = values[first] + values[left] + values[right];
            if (sum == input[0]) {
                result[0] = values[first]; result[1] = values[left]; result[2] = values[right];
                first = item_count;
                break;
            }
            if (sum < input[0]) ++left;
            else --right;
        }
        if (first == item_count) break;
    }
    for (size_t index = 0; index < 3; ++index) put_i64_le(output, index * 8, result[index]);
    return 3;
}
