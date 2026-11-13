// Bounded knapsack by residue-class sliding maxima.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t bounded_knapsack_monotone_queue(const std::int64_t *packed,
                                                          std::size_t length) noexcept
{
    if (packed == nullptr || length < 2 || length > 51) return -1;
    if (packed[0] < 0 || packed[0] > 64 || packed[1] < 0 || packed[1] > 16) return -1;
    const auto capacity = static_cast<std::size_t>(packed[0]);
    const auto types = static_cast<std::size_t>(packed[1]);
    if (length != 2 + 3 * types) return -1;
    for (std::size_t item = 0; item < types; ++item) {
        const auto weight = packed[2 + 3 * item];
        const auto value = packed[3 + 3 * item];
        const auto count = packed[4 + 3 * item];
        if (weight < 1 || weight > 16 || value < 0 || value > 100 || count < 0 || count > 16) return -1;
    }

    std::int64_t dp[65] = {};
    std::int64_t next[65] = {};
    std::int64_t queue_score[65] = {};
    std::size_t queue_index[65] = {};
    for (std::size_t item = 0; item < types; ++item) {
        const auto weight = static_cast<std::size_t>(packed[2 + 3 * item]);
        const auto value = packed[3 + 3 * item];
        const auto count = static_cast<std::size_t>(packed[4 + 3 * item]);
        for (std::size_t residue = 0; residue < weight && residue <= capacity; ++residue) {
            std::size_t head = 0, tail = 0;
            const auto max_t = (capacity - residue) / weight;
            for (std::size_t t = 0; t <= max_t; ++t) {
                const auto current = residue + t * weight;
                const auto score = dp[current] - static_cast<std::int64_t>(t) * value;
                while (tail > head && queue_score[tail - 1] <= score) --tail;
                queue_index[tail] = t;
                queue_score[tail++] = score;
                const auto first_allowed = t > count ? t - count : 0;
                while (head < tail && queue_index[head] < first_allowed) ++head;
                next[current] = static_cast<std::int64_t>(t) * value + queue_score[head];
            }
        }
        for (std::size_t c = 0; c <= capacity; ++c) dp[c] = next[c];
    }
    return dp[capacity];
}
