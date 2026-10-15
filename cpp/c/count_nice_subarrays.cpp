#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_length = 4096; }

extern "C" std::int64_t count_nice_subarrays(const std::int64_t* values, std::size_t length) noexcept {
    if (values == nullptr || length < 2 || values[0] < 0 || values[0] > 4096 || values[1] < 1 || values[1] > 4096) return -1;
    const int n = static_cast<int>(values[0]);
    const int k = static_cast<int>(values[1]);
    if (length != static_cast<std::size_t>(n + 2)) return -1;
    for (int i = 0; i < n; ++i) if (values[i + 2] < INT32_MIN || values[i + 2] > INT32_MAX) return -1;
    std::int32_t memo[max_length] = {};
    int left = 0, odd_count = 0;
    std::int64_t result = 0;
    for (int right = 0; right < n; ++right) {
        if ((static_cast<std::int32_t>(values[right + 2]) & 1) == 1) ++odd_count;
        if (odd_count > k) { left += memo[left]; --odd_count; }
        if (odd_count == k) {
            if (memo[left] == 0) {
                int even_count = 0, temp = left;
                while ((static_cast<std::int32_t>(values[temp + 2]) & 1) == 0) { ++even_count; ++temp; }
                memo[left] = even_count + 1;
            }
            result += memo[left];
        }
    }
    return result;
}
