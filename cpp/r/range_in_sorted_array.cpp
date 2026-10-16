#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_n = 512;
constexpr std::int64_t int32_min_value = -2147483648LL;
constexpr std::int64_t int32_max_value = 2147483647LL;

std::int64_t find_bound(const std::int64_t* values, std::size_t n, std::int64_t key, bool find_left) noexcept {
    std::int64_t left = 0, right = static_cast<std::int64_t>(n) - 1;
    while (left <= right) {
        const auto mid = left + (right - left) / 2;
        if (values[mid] > key) right = mid - 1;
        else if (values[mid] < key) left = mid + 1;
        else if (find_left) {
            if (mid == 0 || values[mid - 1] != key) return mid;
            right = mid - 1;
        } else {
            if (static_cast<std::size_t>(mid) == n - 1 || values[mid + 1] != key) return mid;
            left = mid + 1;
        }
    }
    return -1;
}

void put_i32_le(std::uint8_t* output, std::size_t offset, std::int32_t value) noexcept {
    const auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t i = 0; i < 4; ++i) output[offset + i] = static_cast<std::uint8_t>(bits >> (8 * i));
}
}

extern "C" std::int64_t range_in_sorted_array(const std::int64_t* input, std::size_t length,
                                               std::uint8_t* output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 2 || input[0] < 0 || input[0] > max_n || length != static_cast<std::size_t>(input[0]) + 2) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto key = input[n + 1];
    if (key < int32_min_value || key > int32_max_value) return -1;
    for (std::size_t i = 0; i < n; ++i) {
        if (input[i + 1] < int32_min_value || input[i + 1] > int32_max_value) return -1;
        if (i > 0 && input[i] > input[i + 1]) return -1;
    }
    const auto first = find_bound(input + 1, n, key, true);
    const auto last = find_bound(input + 1, n, key, false);
    if (output == nullptr || output_capacity < 8) return -2;
    put_i32_le(output, 0, static_cast<std::int32_t>(first));
    put_i32_le(output, 4, static_cast<std::int32_t>(last));
    return 8;
}
