// Compare lowercase ASCII strings by their letter frequencies.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_STRING_LENGTH = 1024;
constexpr std::size_t MAX_INPUT_LENGTH = 2 + 2 * MAX_STRING_LENGTH;
}

extern "C" std::int64_t valid_anagram(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const std::uint64_t first = static_cast<std::uint64_t>(input[0]);
    const std::uint64_t second = static_cast<std::uint64_t>(input[1]);
    if (first > MAX_STRING_LENGTH || second > MAX_STRING_LENGTH ||
        length != 2 + first + second) return -1;
    if (first != second) {
        for (std::size_t i = 2; i < length; ++i)
            if (static_cast<std::uint64_t>(input[i]) - 97 > 25) return -1;
        return 0;
    }

    std::uint16_t counts[26] = {0};
    const std::size_t count = static_cast<std::size_t>(first);
    for (std::size_t i = 2; i < 2 + count; ++i) {
        const std::uint64_t left = static_cast<std::uint64_t>(input[i]) - 97;
        const std::uint64_t right = static_cast<std::uint64_t>(input[i + count]) - 97;
        if (left > 25 || right > 25) return -1;
        if (left != right) {
            ++counts[left];
            --counts[right];
        }
    }
    for (std::size_t slot = 0; slot < 26; ++slot)
        if (counts[slot] != 0) return 0;
    return 1;
}
