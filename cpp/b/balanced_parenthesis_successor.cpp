#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxPairs = 10;
constexpr std::size_t kMaxInputLength = 21;
constexpr std::size_t kMaxOutputBytes = 20;
}

extern "C" std::int64_t balanced_parenthesis_successor(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 1 || length > kMaxInputLength) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(kMaxPairs)) return -1;
    const auto pairs = static_cast<std::size_t>(input[0]);
    const auto sequence_length = 2 * pairs;
    if (length != 1 + sequence_length) return -1;
    std::array<std::uint8_t, kMaxOutputBytes> symbols{};
    int balance = 0;
    for (std::size_t i = 0; i < sequence_length; ++i) {
        const auto symbol = input[1 + i];
        if (symbol != 0 && symbol != 1) return -1;
        symbols[i] = static_cast<std::uint8_t>(symbol);
        balance += symbol == 0 ? 1 : -1;
        if (balance < 0) return -1;
    }
    if (balance != 0) return -1;
    if (output == nullptr || capacity < sequence_length) return -2;

    std::array<std::uint8_t, kMaxOutputBytes> staged{};
    int reverse_depth = 0;
    for (std::size_t cursor = sequence_length; cursor > 0; --cursor) {
        const auto i = cursor - 1;
        if (symbols[i] == 0) --reverse_depth;
        else ++reverse_depth;
        if (symbols[i] == 0 && reverse_depth > 0) {
            --reverse_depth;
            const auto suffix_length = sequence_length - i - 1;
            const auto opening_count = static_cast<std::size_t>(
                (static_cast<int>(suffix_length) - reverse_depth) / 2);
            const auto closing_count = suffix_length - opening_count;
            for (std::size_t j = 0; j < i; ++j) staged[j] = symbols[j] == 0 ? '(' : ')';
            staged[i] = ')';
            auto position = i + 1;
            for (std::size_t j = 0; j < opening_count; ++j) staged[position++] = '(';
            for (std::size_t j = 0; j < closing_count; ++j) staged[position++] = ')';
            for (std::size_t j = 0; j < sequence_length; ++j) output[j] = staged[j];
            return static_cast<std::int64_t>(sequence_length);
        }
    }
    return -3;
}
