/* Minimum-regret stable matching by increasing acceptable-rank threshold. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 8;
constexpr std::size_t MAX_INPUT_LENGTH = 129;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) noexcept
{
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t optimal_stable_marriage(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept
{
    if (input == nullptr || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(MAX_N)) return -1;
    const std::size_t n = static_cast<std::size_t>(input[0]);
    const std::size_t side_size = n * n;
    if (length != 1 + 2 * side_size) return -1;

    std::size_t men_preferences[64]{};
    std::size_t women_rank[64]{};
    for (std::size_t row = 0; row < 2 * n; ++row) {
        bool seen[MAX_N]{};
        const std::size_t start = row < n
            ? 1 + row * n
            : 1 + side_size + (row - n) * n;
        for (std::size_t rank = 0; rank < n; ++rank) {
            const std::int64_t value = input[start + rank];
            if (value < 0 || value >= static_cast<std::int64_t>(n) || seen[value]) return -1;
            const std::size_t participant = static_cast<std::size_t>(value);
            seen[participant] = true;
            if (row < n) men_preferences[row * n + rank] = participant;
            else women_rank[(row - n) * n + participant] = rank;
        }
    }
    const std::size_t output_bytes = 16 * n;
    if (output == nullptr || capacity < output_bytes) return -2;

    std::int64_t final_partner[MAX_N];
    for (std::size_t man = 0; man < n; ++man) final_partner[man] = -1;
    for (std::size_t threshold = 0; threshold < n; ++threshold) {
        std::int64_t woman_partner[MAX_N];
        std::int64_t man_partner[MAX_N];
        std::size_t next_rank[MAX_N]{};
        std::size_t queue[MAX_N]{};
        for (std::size_t i = 0; i < n; ++i) {
            woman_partner[i] = -1;
            man_partner[i] = -1;
            queue[i] = i;
        }
        std::size_t head = 0, tail = 0, queued = n;
        while (queued > 0) {
            const std::size_t man = queue[head];
            head = (head + 1) % n;
            --queued;
            while (next_rank[man] < n) {
                const std::size_t rank = next_rank[man]++;
                const std::size_t woman = men_preferences[man * n + rank];
                if (rank > threshold || women_rank[woman * n + man] > threshold) continue;
                const std::int64_t incumbent = woman_partner[woman];
                if (incumbent < 0 || women_rank[woman * n + man] <
                        women_rank[woman * n + static_cast<std::size_t>(incumbent)]) {
                    woman_partner[woman] = static_cast<std::int64_t>(man);
                    man_partner[man] = static_cast<std::int64_t>(woman);
                    if (incumbent >= 0) {
                        man_partner[static_cast<std::size_t>(incumbent)] = -1;
                        queue[tail] = static_cast<std::size_t>(incumbent);
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
        std::size_t matched = 0;
        for (std::size_t man = 0; man < n; ++man) if (man_partner[man] >= 0) ++matched;
        if (matched == n) {
            for (std::size_t man = 0; man < n; ++man) final_partner[man] = man_partner[man];
            break;
        }
    }
    for (std::size_t man = 0; man < n; ++man) {
        store_i64_le(output, (man * 2) * 8, static_cast<std::int64_t>(man));
        store_i64_le(output, (man * 2 + 1) * 8, final_partner[man]);
    }
    return static_cast<std::int64_t>(output_bytes);
}
