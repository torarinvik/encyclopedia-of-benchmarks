#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input_length = 64;

std::int64_t rotated_digit(std::int64_t value)
{
    switch (value) {
        case '0': return '0';
        case '1': return '1';
        case '6': return '9';
        case '8': return '8';
        case '9': return '6';
        default: return -1;
    }
}
} // namespace

extern "C" std::int64_t strobogrammatic_number(const std::int64_t *bytes,
    std::size_t length) noexcept
{
    if ((bytes == nullptr && length != 0) || length > max_input_length) return -1;
    for (std::size_t index = 0; index < length; ++index) {
        if (bytes[index] < 0 || bytes[index] > 127) return -1;
    }
    std::size_t left = 0;
    std::size_t right = length;
    while (left < right) {
        --right;
        if (rotated_digit(bytes[left]) != bytes[right]) return 0;
        ++left;
    }
    return 1;
}
