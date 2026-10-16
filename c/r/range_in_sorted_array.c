#include <stddef.h>
#include <stdint.h>

#define MAX_N 512
#define INT32_MIN_VALUE (-2147483647LL - 1)
#define INT32_MAX_VALUE 2147483647LL

static int64_t find_bound(const int64_t *values, size_t n, int64_t key, int find_left)
{
    int64_t left = 0, right = (int64_t)n - 1;
    while (left <= right) {
        const int64_t mid = left + ((right - left) / 2);
        if (values[mid] > key) right = mid - 1;
        else if (values[mid] < key) left = mid + 1;
        else if (find_left) {
            if (mid == 0 || values[mid - 1] != key) return mid;
            right = mid - 1;
        } else {
            if ((size_t)mid == n - 1 || values[mid + 1] != key) return mid;
            left = mid + 1;
        }
    }
    return -1;
}

static void put_i32_le(uint8_t *output, size_t offset, int32_t value)
{
    const uint32_t bits = (uint32_t)value;
    for (size_t i = 0; i < 4; ++i) output[offset + i] = (uint8_t)(bits >> (8 * i));
}

int64_t range_in_sorted_array(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 2 || input[0] < 0 || input[0] > MAX_N || length != (size_t)input[0] + 2) return -1;
    const size_t n = (size_t)input[0];
    const int64_t key = input[n + 1];
    if (key < INT32_MIN_VALUE || key > INT32_MAX_VALUE) return -1;
    for (size_t i = 0; i < n; ++i) {
        if (input[i + 1] < INT32_MIN_VALUE || input[i + 1] > INT32_MAX_VALUE) return -1;
        if (i > 0 && input[i] > input[i + 1]) return -1;
    }
    const int64_t first = find_bound(input + 1, n, key, 1);
    const int64_t last = find_bound(input + 1, n, key, 0);
    if (output == NULL || output_capacity < 8) return -2;
    put_i32_le(output, 0, (int32_t)first);
    put_i32_le(output, 4, (int32_t)last);
    return 8;
}
