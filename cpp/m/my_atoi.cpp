#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input_length = 256;
constexpr std::int64_t int32_max_value = 2147483647;
constexpr std::int64_t int32_min_magnitude = 2147483648;
constexpr std::int64_t invalid_result = -9'223'372'036'854'775'807LL - 1LL;
}

extern "C" std::int64_t my_atoi(const std::int64_t* input, std::size_t length) {
    if (input == nullptr) return 0;
    if (length > max_input_length) return invalid_result;
    for (std::size_t i = 0; i < length; ++i) if (input[i] < 0 || input[i] > 127) return invalid_result;

    std::size_t start = 0, end = length;
    while (start < end && input[start] <= 0x20) ++start;
    while (end > start && input[end - 1] <= 0x20) --end;
    if (start == end) return 0;

    bool negative = false;
    if (input[start] == '+' || input[start] == '-') {
        negative = input[start] == '-';
        ++start;
    }
    const std::int64_t limit = negative ? int32_min_magnitude : int32_max_value;
    std::int64_t magnitude = 0;
    while (start < end && input[start] >= '0' && input[start] <= '9') {
        const auto digit = input[start] - '0';
        if (magnitude > limit / 10 || (magnitude == limit / 10 && digit > limit % 10))
            return negative ? -int32_min_magnitude : int32_max_value;
        magnitude = magnitude * 10 + digit;
        ++start;
    }
    return negative ? -magnitude : magnitude;
}
