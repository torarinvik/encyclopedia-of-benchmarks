/* Bounded knapsack by residue-class sliding maxima. */
#include <stddef.h>
#include <stdint.h>

int64_t bounded_knapsack_monotone_queue(const int64_t *packed, size_t length)
{
    if (packed == NULL || length < 2 || length > 51) return -1;
    if (packed[0] < 0 || packed[0] > 64 || packed[1] < 0 || packed[1] > 16) return -1;
    const size_t capacity = (size_t)packed[0];
    const size_t types = (size_t)packed[1];
    if (length != 2 + 3 * types) return -1;
    for (size_t i = 0; i < types; ++i) {
        const int64_t weight = packed[2 + 3 * i];
        const int64_t value = packed[3 + 3 * i];
        const int64_t count = packed[4 + 3 * i];
        if (weight < 1 || weight > 16 || value < 0 || value > 100 || count < 0 || count > 16) return -1;
    }

    int64_t dp[65] = {0};
    int64_t next[65] = {0};
    int64_t queue_score[65] = {0};
    size_t queue_index[65] = {0};
    for (size_t item = 0; item < types; ++item) {
        const size_t weight = (size_t)packed[2 + 3 * item];
        const int64_t value = packed[3 + 3 * item];
        const size_t count = (size_t)packed[4 + 3 * item];
        for (size_t residue = 0; residue < weight && residue <= capacity; ++residue) {
            size_t head = 0;
            size_t tail = 0;
            const size_t max_t = (capacity - residue) / weight;
            for (size_t t = 0; t <= max_t; ++t) {
                const size_t current = residue + t * weight;
                const int64_t score = dp[current] - (int64_t)t * value;
                while (tail > head && queue_score[tail - 1] <= score) --tail;
                queue_index[tail] = t;
                queue_score[tail] = score;
                ++tail;
                const size_t first_allowed = t > count ? t - count : 0;
                while (head < tail && queue_index[head] < first_allowed) ++head;
                next[current] = (int64_t)t * value + queue_score[head];
            }
        }
        for (size_t c = 0; c <= capacity; ++c) dp[c] = next[c];
    }
    return dp[capacity];
}
