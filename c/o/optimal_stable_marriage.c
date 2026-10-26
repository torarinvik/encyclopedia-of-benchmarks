/* Minimum-regret stable matching by increasing acceptable-rank threshold. */
#include <stddef.h>
#include <stdint.h>

#define MAX_N 8
#define MAX_INPUT_LENGTH 129

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 255);
        bits >>= 8;
    }
}

int64_t optimal_stable_marriage(const int64_t *input, size_t length,
                                uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    const size_t side_size = n * n;
    if (length != 1 + 2 * side_size) return -1;

    size_t men_preferences[64] = {0};
    size_t women_rank[64] = {0};
    for (size_t row = 0; row < 2 * n; ++row) {
        uint8_t seen[MAX_N] = {0};
        const size_t start = row < n
            ? 1 + row * n
            : 1 + side_size + (row - n) * n;
        for (size_t rank = 0; rank < n; ++rank) {
            const int64_t value = input[start + rank];
            if (value < 0 || value >= (int64_t)n || seen[value]) return -1;
            const size_t participant = (size_t)value;
            seen[participant] = 1;
            if (row < n) {
                men_preferences[row * n + rank] = participant;
            } else {
                women_rank[(row - n) * n + participant] = rank;
            }
        }
    }

    const size_t output_bytes = 16 * n;
    if (output == NULL || capacity < output_bytes) return -2;

    int64_t final_partner[MAX_N];
    for (size_t man = 0; man < n; ++man) final_partner[man] = -1;
    for (size_t threshold = 0; threshold < n; ++threshold) {
        int64_t woman_partner[MAX_N];
        int64_t man_partner[MAX_N];
        size_t next_rank[MAX_N] = {0};
        size_t queue[MAX_N];
        for (size_t i = 0; i < n; ++i) {
            woman_partner[i] = -1;
            man_partner[i] = -1;
            queue[i] = i;
        }
        size_t head = 0, tail = 0, queued = n;
        while (queued > 0) {
            const size_t man = queue[head];
            head = (head + 1) % n;
            --queued;
            while (next_rank[man] < n) {
                const size_t rank = next_rank[man]++;
                const size_t woman = men_preferences[man * n + rank];
                if (rank > threshold || women_rank[woman * n + man] > threshold) continue;
                const int64_t incumbent = woman_partner[woman];
                if (incumbent < 0 || women_rank[woman * n + man] <
                        women_rank[woman * n + (size_t)incumbent]) {
                    woman_partner[woman] = (int64_t)man;
                    man_partner[man] = (int64_t)woman;
                    if (incumbent >= 0) {
                        man_partner[(size_t)incumbent] = -1;
                        queue[tail] = (size_t)incumbent;
                        tail = (tail + 1) % n;
                        ++queued;
                    }
                    break;
                }
                queue[tail] = man;
                tail = (tail + 1) % n;
                ++queued;
                break;
            }
        }
        size_t matched = 0;
        for (size_t man = 0; man < n; ++man) {
            if (man_partner[man] >= 0) ++matched;
        }
        if (matched == n) {
            for (size_t man = 0; man < n; ++man) final_partner[man] = man_partner[man];
            break;
        }
    }

    for (size_t man = 0; man < n; ++man) {
        store_i64_le(output, (man * 2) * 8, (int64_t)man);
        store_i64_le(output, (man * 2 + 1) * 8, final_partner[man]);
    }
    return (int64_t)output_bytes;
}
