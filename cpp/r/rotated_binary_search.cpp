#include <cstddef>
#include <cstdint>
#include <limits>

extern "C" std::int64_t rotated_binary_search(const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 2 || input[0] < 0 || input[0] > 256 || length != static_cast<std::size_t>(input[0]) + 2) return -2;
    const std::size_t n = static_cast<std::size_t>(input[0]); if (n == 0) return -1;
    const auto key = input[n + 1]; if (key < std::numeric_limits<std::int32_t>::min() || key > std::numeric_limits<std::int32_t>::max()) return -2;
    std::size_t drops = 0;
    for (std::size_t i = 0; i < n; ++i) {
        if (input[i + 1] < std::numeric_limits<std::int32_t>::min() || input[i + 1] > std::numeric_limits<std::int32_t>::max()) return -2;
        if (i > 0 && input[i] > input[i + 1]) ++drops;
    }
    if (drops > 1 || (drops == 1 && input[n] > input[1])) return -2;
    std::size_t left = 0, right = n - 1;
    while (left <= right) {
        const std::size_t middle = left + (right - left) / 2; const auto mid = input[middle + 1];
        if (key == mid) return static_cast<std::int64_t>(middle);
        if (input[left + 1] == mid && mid == input[right + 1]) { ++left; if (right == 0) break; --right; continue; }
        if (input[left + 1] <= mid) {
            if (input[left + 1] <= key && key < mid) { if (middle == 0) break; right = middle - 1; } else left = middle + 1;
        } else {
            if (mid < key && key <= input[right + 1]) left = middle + 1; else { if (middle == 0) break; right = middle - 1; }
        }
    }
    return -1;
}
