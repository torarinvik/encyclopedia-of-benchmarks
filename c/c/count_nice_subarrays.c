#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 4096

int64_t count_nice_subarrays(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || values[0] < 0 || values[0] > MAX_LENGTH || values[1] < 1 || values[1] > MAX_LENGTH) return -1;
    const size_t n = (size_t)values[0];
    const int32_t k = (int32_t)values[1];
    if (length != n + 2) return -1;
    for (size_t i = 0; i < n; ++i)
        if (values[i + 2] < INT32_MIN || values[i + 2] > INT32_MAX) return -1;
    int32_t memo[MAX_LENGTH] = {0};
    size_t left = 0;
    int32_t odd_count = 0;
    int64_t result = 0;
    for (size_t right = 0; right < n; ++right) {
        if (((int32_t)values[right + 2] & 1) == 1) ++odd_count;
        if (odd_count > k) {
            left += (size_t)memo[left];
            --odd_count;
        }
        if (odd_count == k) {
            if (memo[left] == 0) {
                size_t even_count = 0, temp = left;
                while ((((int32_t)values[temp + 2]) & 1) == 0) { ++even_count; ++temp; }
                memo[left] = (int32_t)(even_count + 1);
            }
            result += memo[left];
        }
    }
    return result;
}
