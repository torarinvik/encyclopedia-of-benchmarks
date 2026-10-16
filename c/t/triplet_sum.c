#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 10

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

static void sort_three(int64_t *first, int64_t *second, int64_t *third) {
    if (*first > *second) { int64_t value = *first; *first = *second; *second = value; }
    if (*second > *third) { int64_t value = *second; *second = *third; *third = value; }
    if (*first > *second) { int64_t value = *first; *first = *second; *second = value; }
}

int64_t triplet_sum(const int64_t *input, size_t length,
                    uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 1 || length > MAX_ITEMS + 1 ||
        input[0] < -3000000 || input[0] > 3000000) return -1;
    const size_t item_count = length - 1;
    for (size_t index = 0; index < item_count; ++index)
        if (input[index + 1] < -1000000 || input[index + 1] > 1000000) return -1;
    if (output_capacity < 24 || output == NULL) return -2;

    int64_t result[3] = {0, 0, 0};
    int found = 0;
    for (size_t first = 0; first < item_count && !found; ++first) {
        for (size_t second = 0; second < item_count && !found; ++second) {
            if (second == first) continue;
            for (size_t third = 0; third < item_count; ++third) {
                if (third == first || third == second) continue;
                if (input[first + 1] + input[second + 1] + input[third + 1] == input[0]) {
                    result[0] = input[first + 1];
                    result[1] = input[second + 1];
                    result[2] = input[third + 1];
                    sort_three(&result[0], &result[1], &result[2]);
                    found = 1;
                    break;
                }
            }
        }
    }
    for (size_t index = 0; index < 3; ++index) put_i64_le(output, index * 8, result[index]);
    return 3;
}
