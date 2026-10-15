#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_sequence_length = 4096;
constexpr std::size_t max_packed_length = 8194;

bool is_unicode_scalar(std::int64_t value) noexcept {
    return value >= 0 && value <= 1114111 && !(value >= 55296 && value <= 57343);
}
}

extern "C" std::int64_t is_subsequence(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_packed_length) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_sequence_length) ||
        input[1] < 0 || input[1] > static_cast<std::int64_t>(max_sequence_length)) return -1;
    const auto main_length = static_cast<std::size_t>(input[0]);
    const auto subsequence_length = static_cast<std::size_t>(input[1]);
    if (length != 2 + main_length + subsequence_length) return -1;
    for (std::size_t index = 2; index < length; ++index)
        if (!is_unicode_scalar(input[index])) return -1;

    const std::size_t subsequence_start = 2 + main_length;
    std::size_t main_index = 0, subsequence_index = 0;
    while (subsequence_index < subsequence_length && main_index < main_length) {
        if (input[subsequence_start + subsequence_index] == input[2 + main_index]) ++subsequence_index;
        ++main_index;
    }
    return subsequence_index == subsequence_length ? 1 : 0;
}
