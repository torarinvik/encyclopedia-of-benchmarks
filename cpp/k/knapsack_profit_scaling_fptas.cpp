#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxN = 12, MaxInput = 26, MaxQ = 4 * MaxN * MaxN;
void store(std::uint8_t *out, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) { out[offset + b] = static_cast<std::uint8_t>(bits & 255U); bits >>= 8; }
}
}

extern "C" std::int64_t knapsack_profit_scaling_fptas(
    const std::int64_t *input, std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (!input || length < 4 || length > MaxInput) return -1;
    auto cap = input[0], n64 = input[1];
    if (cap < 1 || cap > 100 || n64 < 1 || n64 > static_cast<std::int64_t>(MaxN)
        || length != 2 + 2 * static_cast<std::size_t>(n64)) return -1;
    auto n = static_cast<std::size_t>(n64);
    std::int64_t weights[MaxN]{}, profits[MaxN]{};
    for (std::size_t i = 0; i < n; ++i) {
        weights[i] = input[2 + 2 * i]; profits[i] = input[3 + 2 * i];
        if (weights[i] < 1 || weights[i] > 100 || profits[i] < 1 || profits[i] > 10000) return -1;
    }
    if (!output || capacity < 16) return -2;
    std::size_t order[MaxN]{};
    std::size_t eligible = 0;
    for (std::size_t i = 0; i < n; ++i) if (weights[i] <= cap) order[eligible++] = i;
    for (std::size_t i = 1; i < eligible; ++i) {
        auto key = order[i]; auto j = i;
        while (j > 0 && profits[key] * weights[order[j - 1]] > profits[order[j - 1]] * weights[key]) {
            order[j] = order[j - 1]; --j;
        }
        order[j] = key;
    }
    std::int64_t upper = 0, room = cap;
    for (std::size_t k = 0; k < eligible; ++k) {
        auto i = order[k];
        if (weights[i] <= room) { upper += profits[i]; room -= weights[i]; }
        else { upper += profits[i] * room / weights[i]; break; }
    }
    std::int64_t dpWeight[MaxQ + 1], dpMask[MaxQ + 1];
    for (std::size_t q = 0; q <= MaxQ; ++q) { dpWeight[q] = cap + 1; dpMask[q] = 0; }
    dpWeight[0] = 0; std::size_t reachable = 0;
    if (upper > 0) for (std::size_t i = 0; i < n; ++i) {
        if (weights[i] > cap) continue;
        auto value = static_cast<std::size_t>(4 * static_cast<std::int64_t>(n) * profits[i] / upper);
        if (!value) continue;
        for (std::size_t q = reachable + 1; q > 0; --q) {
            auto old = q - 1; if (dpWeight[old] > cap) continue;
            auto next = old + value; auto newWeight = dpWeight[old] + weights[i];
            auto newMask = dpMask[old] | (std::int64_t{1} << i);
            if (newWeight < dpWeight[next] || (newWeight == dpWeight[next] && newMask < dpMask[next])) {
                dpWeight[next] = newWeight; dpMask[next] = newMask;
            }
        }
        reachable += value;
    }
    std::size_t best = 0;
    for (std::size_t q = 1; q <= MaxQ; ++q) if (dpWeight[q] <= cap) best = q;
    auto mask = dpMask[best]; std::int64_t value = 0;
    for (std::size_t i = 0; i < n; ++i) if ((static_cast<std::uint64_t>(mask) >> i) & 1U) value += profits[i];
    store(output, 0, mask); store(output, 8, value); return 16;
}
