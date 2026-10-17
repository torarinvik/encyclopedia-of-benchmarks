/* Men-proposing deferred acceptance for bounded complete preference lists. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 8;
constexpr std::size_t MAX_INPUT_LENGTH = 129;
}

extern "C" std::int64_t stable_matching(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept
{
    if (input == nullptr || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(MAX_N)) return -1;
    const std::size_t n = static_cast<std::size_t>(input[0]);
    const std::size_t side_size = n * n;
    if (length != 1 + 2 * side_size) return -1;

    std::int64_t men_preferences[64]{};
    std::int64_t women_rank[64]{};
    for (std::size_t row = 0; row < 2 * n; ++row) {
        bool seen[8]{};
        const std::size_t row_start = row < n
            ? 1 + row * n
            : 1 + side_size + (row - n) * n;
        for (std::size_t rank = 0; rank < n; ++rank) {
            const std::int64_t participant = input[row_start + rank];
            if (participant < 0 || participant >= static_cast<std::int64_t>(n) || seen[participant]) return -1;
            seen[participant] = true;
            if (row < n) men_preferences[row * n + rank] = participant;
            else women_rank[(row - n) * n + static_cast<std::size_t>(participant)] = static_cast<std::int64_t>(rank);
        }
    }

    const std::size_t output_bytes = 16 * n;
    if (output == nullptr || capacity < output_bytes) return -2;

    std::int64_t woman_partner[8];
    std::int64_t man_partner[8];
    std::size_t next_proposal[8]{};
    std::size_t free_queue[8]{};
    for (std::size_t index = 0; index < n; ++index) {
        woman_partner[index] = -1;
        man_partner[index] = -1;
        free_queue[index] = index;
    }
    std::size_t head = 0, tail = 0, queue_count = n;
    while (queue_count > 0) {
        const std::size_t man = free_queue[head];
        head = (head + 1) % n;
        --queue_count;
        const std::size_t rank = next_proposal[man]++;
        const std::size_t woman = static_cast<std::size_t>(men_preferences[man * n + rank]);
        const std::int64_t incumbent = woman_partner[woman];
        if (incumbent < 0) {
            woman_partner[woman] = static_cast<std::int64_t>(man);
            man_partner[man] = static_cast<std::int64_t>(woman);
        } else if (women_rank[woman * n + man] < women_rank[woman * n + static_cast<std::size_t>(incumbent)]) {
            woman_partner[woman] = static_cast<std::int64_t>(man);
            man_partner[man] = static_cast<std::int64_t>(woman);
            man_partner[static_cast<std::size_t>(incumbent)] = -1;
            free_queue[tail] = static_cast<std::size_t>(incumbent);
            tail = (tail + 1) % n;
            ++queue_count;
        } else {
            free_queue[tail] = man;
            tail = (tail + 1) % n;
            ++queue_count;
        }
    }

    for (std::size_t man = 0; man < n; ++man) {
        const std::int64_t pair[2] = {static_cast<std::int64_t>(man), man_partner[man]};
        for (std::size_t item = 0; item < 2; ++item) {
            std::uint64_t bits = static_cast<std::uint64_t>(pair[item]);
            for (std::size_t byte = 0; byte < 8; ++byte) {
                output[(man * 2 + item) * 8 + byte] = static_cast<std::uint8_t>(bits & 255);
                bits >>= 8;
            }
        }
    }
    return static_cast<std::int64_t>(output_bytes);
}
