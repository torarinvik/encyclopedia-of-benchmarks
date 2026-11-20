#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 32;
constexpr std::size_t min_k = 2;
constexpr std::size_t max_k = 4;
constexpr std::size_t max_input = 99;
constexpr std::size_t max_words = 97;
constexpr std::int64_t distance_limit = 1000000;
constexpr std::int64_t end_sentinel = 1000001;

struct Interval { std::int64_t id, rank, first, past; };

void put_i64(std::uint8_t *output, std::size_t word, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[8 * word + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t all_distances_bottom_k_interval_updates(
        const std::int64_t *input, std::size_t length,
        std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > max_input) return -1;
    const auto n0 = input[0], k0 = input[1];
    if (n0 < 2 || n0 > static_cast<std::int64_t>(max_n)
            || k0 < static_cast<std::int64_t>(min_k)
            || k0 > static_cast<std::int64_t>(max_k) || k0 > n0) return -1;
    const auto n = static_cast<std::size_t>(n0);
    const auto k = static_cast<std::size_t>(k0);
    if (length != 2 + 3 * n) return -1;

    std::array<Interval, max_n> records{};
    std::array<bool, max_n> seen_id{}, seen_rank{};
    for (std::size_t i = 0; i < n; ++i) {
        records[i] = {input[2 + 3*i], input[4 + 3*i], input[3 + 3*i], 0};
        const auto id = records[i].id, rank = records[i].rank, d = records[i].first;
        if (id < 0 || id >= n0 || seen_id[static_cast<std::size_t>(id)]
                || rank < 0 || rank >= n0 || seen_rank[static_cast<std::size_t>(rank)]
                || d < 0 || d > distance_limit) return -1;
        seen_id[static_cast<std::size_t>(id)] = true;
        seen_rank[static_cast<std::size_t>(rank)] = true;
        for (std::size_t j = 0; j < i; ++j)
            if (records[j].first == d) return -1;
    }
    for (std::size_t i = 1; i < k; ++i)
        if (records[i-1].first >= records[i].first) return -1;
    for (std::size_t i = k; i < n; ++i)
        if (records[i].first <= records[k-1].first) return -1;

    std::array<Interval, max_n> intervals{};
    std::size_t count = k;
    for (std::size_t i = 0; i < k; ++i)
        intervals[i] = {records[i].id, records[i].rank, records[i].first, end_sentinel};
    for (std::size_t i = k; i < n; ++i) {
        std::size_t worst = max_n, active = 0;
        for (std::size_t j = 0; j < count; ++j) {
            const auto &entry = intervals[j];
            if (entry.first <= records[i].first && records[i].first < entry.past) {
                ++active;
                if (worst == max_n || entry.rank > intervals[worst].rank) worst = j;
            }
        }
        if (active != k || worst == max_n) return -1;
        if (records[i].rank >= intervals[worst].rank) continue;

        auto cursor = intervals[worst].past;
        intervals[worst].past = records[i].first;
        while (cursor < end_sentinel) {
            std::size_t next_worst = max_n;
            for (std::size_t j = 0; j < count; ++j) {
                const auto &entry = intervals[j];
                if (entry.first <= cursor && cursor < entry.past
                        && (next_worst == max_n
                            || entry.rank > intervals[next_worst].rank)) next_worst = j;
            }
            if (next_worst == max_n || intervals[next_worst].rank <= records[i].rank)
                break;
            const auto next = intervals[next_worst].past;
            intervals[next_worst].past = cursor;
            cursor = next;
        }
        intervals[count++] = {records[i].id, records[i].rank, records[i].first, cursor};
    }

    std::array<std::size_t, max_n> order{};
    std::size_t out_count = 0;
    for (std::size_t i = 0; i < count; ++i)
        if (intervals[i].first < intervals[i].past) order[out_count++] = i;
    for (std::size_t i = 1; i < out_count; ++i) {
        const auto key = order[i];
        std::size_t j = i;
        while (j > 0 && (intervals[order[j-1]].first > intervals[key].first
                || (intervals[order[j-1]].first == intervals[key].first
                    && intervals[order[j-1]].id > intervals[key].id))) {
            order[j] = order[j-1];
            --j;
        }
        order[j] = key;
    }
    std::array<std::int64_t, max_words> staged{};
    staged[0] = static_cast<std::int64_t>(out_count);
    for (std::size_t i = 0; i < out_count; ++i) {
        const auto &entry = intervals[order[i]];
        staged[1 + 3*i] = entry.id;
        staged[2 + 3*i] = entry.first;
        staged[3 + 3*i] = entry.past;
    }
    const auto bytes = 8 * (1 + 3 * out_count);
    if (output == nullptr || capacity < bytes) return -2;
    for (std::size_t word = 0; word < 1 + 3 * out_count; ++word)
        put_i64(output, word, staged[word]);
    return static_cast<std::int64_t>(bytes);
}
