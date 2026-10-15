#include <stddef.h>
#include <stdint.h>

int64_t rotated_binary_search(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || input[0] < 0 || input[0] > 256 || length != (size_t)input[0] + 2) return -2;
    size_t n = (size_t)input[0];
    if (n == 0) return -1;
    int64_t key = input[n + 1];
    if (key < INT32_MIN || key > INT32_MAX) return -2;
    size_t drops = 0;
    for (size_t i = 0; i < n; ++i) {
        if (input[i + 1] < INT32_MIN || input[i + 1] > INT32_MAX) return -2;
        if (i > 0 && input[i] > input[i + 1]) ++drops;
    }
    if (drops > 1 || (drops == 1 && input[n] > input[1])) return -2;
    size_t left = 0, right = n - 1;
    while (left <= right) {
        size_t middle = left + (right - left) / 2;
        int64_t mid = input[middle + 1];
        if (key == mid) return (int64_t)middle;
        if (input[left + 1] == mid && mid == input[right + 1]) { ++left; if (right == 0) break; --right; continue; }
        if (input[left + 1] <= mid) {
            if (input[left + 1] <= key && key < mid) { if (middle == 0) break; right = middle - 1; }
            else left = middle + 1;
        } else {
            if (mid < key && key <= input[right + 1]) left = middle + 1;
            else { if (middle == 0) break; right = middle - 1; }
        }
    }
    return -1;
}
