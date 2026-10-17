#include <stddef.h>
#include <stdint.h>
#define MAX_N 64
#define MAX_INPUT_LENGTH 66

static int search_recursive(const int32_t *items, int left, int right, int32_t target) {
    if (left > right) return -1;
    if (items[left] == target) return left;
    if (items[right] == target) return right;
    return search_recursive(items, left + 1, right - 1, target);
}

int64_t recursive_linear_search(const int64_t *input, size_t length) {
    if (input == NULL || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 2 || input[0] > MAX_N || length != (size_t)input[0] + 2) return -1;
    if (input[1] < INT32_MIN || input[1] > INT32_MAX) return -1;
    const size_t n = (size_t)input[0];
    int32_t items[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        if (input[i + 2] < INT32_MIN || input[i + 2] > INT32_MAX) return -1;
        items[i] = (int32_t)input[i + 2];
        for (size_t j = 0; j < i; ++j) if (items[j] == items[i]) return -1;
    }
    return search_recursive(items, 0, (int)n - 1, (int32_t)input[1]);
}
