#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input_length = 256;

bool is_hex_digit(std::int64_t value) {
    return (value >= '0' && value <= '9') || (value >= 'a' && value <= 'f') ||
           (value >= 'A' && value <= 'F');
}

bool valid_ipv6_text(const std::int64_t *input, std::size_t start, std::size_t length) {
    if (length == 0) return false;
    std::size_t groups = 0, group_length = 0, compression_count = 0;
    bool in_group = false;
    for (std::size_t index = 0; index < length;) {
        const auto value = input[start + index];
        if (value == ':') {
            if (index + 1 < length && input[start + index + 1] == ':') {
                if ((index > 0 && input[start + index - 1] == ':') ||
                    (index + 2 < length && input[start + index + 2] == ':') || compression_count != 0) return false;
                if (in_group) {
                    ++groups;
                    in_group = false;
                    group_length = 0;
                } else if (index != 0) {
                    return false;
                }
                ++compression_count;
                index += 2;
                continue;
            }
            if (index == 0 || index + 1 == length || !in_group) return false;
            ++groups;
            in_group = false;
            group_length = 0;
            ++index;
            continue;
        }
        if (!is_hex_digit(value) || group_length == 4) return false;
        ++group_length;
        in_group = true;
        ++index;
    }
    if (in_group) ++groups;
    return compression_count == 0 ? groups == 8 : groups < 8;
}
}  // namespace

extern "C" std::int64_t is_ipv6_address_valid(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 1 || input[0] < 0 || input[0] > static_cast<std::int64_t>(max_input_length)) return -1;
    const auto text_length = static_cast<std::size_t>(input[0]);
    if (length != text_length + 1) return -1;
    for (std::size_t index = 0; index < text_length; ++index) {
        if (input[index + 1] < 0 || input[index + 1] > 127) return -1;
    }
    return valid_ipv6_text(input, 1, text_length) ? 1 : 0;
}
