#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_input_length = 32; }

extern "C" std::int64_t is_ip_v4_address_valid(const std::int64_t *bytes,
    std::size_t length) noexcept
{
    if ((bytes == nullptr && length != 0) || length > max_input_length) return -1;
    for (std::size_t index = 0; index < length; ++index) {
        if (bytes[index] < 0 || bytes[index] > 127) return -1;
    }
    std::size_t segment_count = 0;
    std::size_t digit_count = 0;
    std::int64_t octet = 0;
    bool leading_zero = false;
    for (std::size_t index = 0; index < length; ++index) {
        const auto value = bytes[index];
        if (value == '.') {
            if (digit_count == 0 || octet > 255 || segment_count >= 3) return 0;
            ++segment_count;
            digit_count = 0;
            octet = 0;
            leading_zero = false;
        } else {
            if (value < '0' || value > '9') return 0;
            if (digit_count == 0) leading_zero = value == '0';
            else if (leading_zero) return 0;
            octet = octet * 10 + value - '0';
            if (octet > 255) return 0;
            ++digit_count;
            if (digit_count > 3) return 0;
        }
    }
    return segment_count == 3 && digit_count > 0 && octet <= 255;
}
