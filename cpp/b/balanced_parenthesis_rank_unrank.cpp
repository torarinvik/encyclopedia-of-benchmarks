#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxPairs = 10;
constexpr std::size_t kMaxInputLength = 22;
constexpr std::size_t kWaysStride = 11;
constexpr std::size_t kWaysCount = 231;
}

extern "C" std::int64_t balanced_parenthesis_rank_unrank(
    const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > kMaxInputLength) return -1;
    const auto mode = input[0], pairs_value = input[1];
    if (pairs_value < 1 || pairs_value > static_cast<std::int64_t>(kMaxPairs)) return -1;
    const auto pairs = static_cast<std::size_t>(pairs_value);
    const auto sequence_length = 2 * pairs;
    if (mode == 0) {
        if (length != 2 + sequence_length) return -1;
        int balance = 0;
        for (std::size_t i = 0; i < sequence_length; ++i) {
            const auto symbol = input[2 + i];
            if (symbol != 0 && symbol != 1) return -1;
            balance += symbol == 0 ? 1 : -1;
            if (balance < 0) return -1;
        }
        if (balance != 0) return -1;
    } else if (mode == 1) {
        if (length != 3) return -1;
    } else {
        return -1;
    }

    std::array<std::int64_t, kWaysCount> ways{};
    ways[0] = 1;
    for (std::size_t remaining = 1; remaining <= sequence_length; ++remaining) {
        for (std::size_t balance = 0; balance <= pairs; ++balance) {
            std::int64_t count = 0;
            if (balance < pairs) count += ways[(remaining - 1) * kWaysStride + balance + 1];
            if (balance > 0) count += ways[(remaining - 1) * kWaysStride + balance - 1];
            ways[remaining * kWaysStride + balance] = count;
        }
    }

    if (mode == 0) {
        std::int64_t rank = 0;
        std::size_t balance = 0;
        for (std::size_t i = 0; i < sequence_length; ++i) {
            const auto symbol = input[2 + i];
            const auto remaining = sequence_length - i - 1;
            if (symbol == 1 && balance < pairs)
                rank += ways[remaining * kWaysStride + balance + 1];
            balance = symbol == 0 ? balance + 1 : balance - 1;
        }
        return rank;
    }

    std::int64_t rank = input[2];
    if (rank < 0 || rank >= ways[sequence_length * kWaysStride]) return -1;
    std::size_t balance = 0;
    std::uint64_t code = 0;
    for (std::size_t i = 0; i < sequence_length; ++i) {
        const auto remaining = sequence_length - i - 1;
        const auto opening_count = balance < pairs
            ? ways[remaining * kWaysStride + balance + 1] : 0;
        std::uint64_t symbol;
        if (rank < opening_count) {
            symbol = 0;
            ++balance;
        } else {
            rank -= opening_count;
            symbol = 1;
            --balance;
        }
        code = (code << 1) | symbol;
    }
    return static_cast<std::int64_t>(code);
}
