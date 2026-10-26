#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxN = 32, MaxInput = 35;
void storeI64LE(std::uint8_t* out, std::size_t offset, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        out[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t max_sum_length_bounded_segment(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    if (!input || length < 4 || length > MaxInput) return -1;
    const auto n64 = input[0], lower64 = input[1], upper64 = input[2];
    if (n64 < 1 || n64 > static_cast<std::int64_t>(MaxN) || lower64 < 1 ||
        upper64 < lower64 || upper64 > n64 || length != 3 + static_cast<std::size_t>(n64)) return -1;
    const auto n = static_cast<std::size_t>(n64), lower = static_cast<std::size_t>(lower64),
        upper = static_cast<std::size_t>(upper64);
    std::int64_t prefix[MaxN + 1]{};
    for (std::size_t i = 0; i < n; ++i) {
        const auto value = input[3 + i];
        if (value < -10000 || value > 10000) return -1;
        prefix[i + 1] = prefix[i] + value;
    }
    if (!output || capacity < 24) return -2;
    std::size_t deque[MaxN + 1]{}, head = 0, tail = 0;
    std::int64_t bestSum = 0;
    std::size_t bestStart = 0, bestEnd = 0;
    bool haveBest = false;
    for (std::size_t end = lower; end <= n; ++end) {
        const auto added = end - lower;
        while (tail > head && prefix[deque[tail - 1]] > prefix[added]) --tail;
        deque[tail++] = added;
        const auto earliest = end > upper ? end - upper : 0;
        while (head < tail && deque[head] < earliest) ++head;
        const auto start = deque[head];
        const auto sum = prefix[end] - prefix[start];
        if (!haveBest || sum > bestSum ||
            (sum == bestSum && (start < bestStart || (start == bestStart && end < bestEnd)))) {
            bestSum = sum; bestStart = start; bestEnd = end; haveBest = true;
        }
    }
    storeI64LE(output, 0, bestSum);
    storeI64LE(output, 8, static_cast<std::int64_t>(bestStart));
    storeI64LE(output, 16, static_cast<std::int64_t>(bestEnd));
    return 24;
}
