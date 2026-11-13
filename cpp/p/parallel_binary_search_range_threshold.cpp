#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 16;
constexpr std::size_t max_events = 32;
constexpr std::size_t max_queries = 32;
constexpr std::size_t max_parseable_length = 196;

void bit_add(std::int64_t* bit, std::size_t index, std::int64_t delta,
             std::size_t limit) {
    while (index <= limit + 1) {
        bit[index] += delta;
        index += index & (0 - index);
    }
}

std::int64_t bit_sum(const std::int64_t* bit, std::size_t index) {
    std::int64_t total = 0;
    while (index > 0) {
        total += bit[index];
        index -= index & (0 - index);
    }
    return total;
}

void range_add(std::int64_t* bit1, std::int64_t* bit2, std::size_t n,
               std::size_t left, std::size_t right, std::int64_t delta) {
    const auto lo = left + 1;
    const auto hi = right + 1;
    bit_add(bit1, lo, delta, n);
    bit_add(bit1, hi + 1, -delta, n);
    bit_add(bit2, lo, delta * static_cast<std::int64_t>(lo - 1), n);
    bit_add(bit2, hi + 1, -delta * static_cast<std::int64_t>(hi), n);
}

std::int64_t prefix_sum(const std::int64_t* bit1, const std::int64_t* bit2,
                        std::size_t count) {
    return static_cast<std::int64_t>(count) * bit_sum(bit1, count) - bit_sum(bit2, count);
}

std::int64_t range_sum(const std::int64_t* bit1, const std::int64_t* bit2,
                       std::size_t left, std::size_t right) {
    return prefix_sum(bit1, bit2, right + 1) - prefix_sum(bit1, bit2, left);
}

std::int64_t solve(const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 3 || length > max_parseable_length) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_n) ||
        input[1] < 0 || input[1] > static_cast<std::int64_t>(max_events) ||
        input[2] < 0 || input[2] > static_cast<std::int64_t>(max_queries)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto event_count = static_cast<std::size_t>(input[1]);
    const auto query_count = static_cast<std::size_t>(input[2]);
    if (length != 3 + 3 * event_count + 3 * query_count) return -1;

    std::int64_t event_left[max_events], event_right[max_events], event_delta[max_events];
    std::int64_t query_left[max_queries], query_right[max_queries], query_target[max_queries];
    std::size_t cursor = 3;
    for (std::size_t event = 0; event < event_count; ++event) {
        const auto left = input[cursor++];
        const auto right = input[cursor++];
        const auto delta = input[cursor++];
        if (left < 0 || left > right || right >= static_cast<std::int64_t>(n) ||
            delta < 0 || delta > 1000) return -1;
        event_left[event] = left;
        event_right[event] = right;
        event_delta[event] = delta;
    }
    for (std::size_t query = 0; query < query_count; ++query) {
        const auto left = input[cursor++];
        const auto right = input[cursor++];
        const auto target = input[cursor++];
        if (left < 0 || left > right || right >= static_cast<std::int64_t>(n) ||
            target < 1 || target > 512000) return -1;
        query_left[query] = left;
        query_right[query] = right;
        query_target[query] = target;
    }

    std::int64_t low[max_queries] = {};
    std::int64_t high[max_queries];
    std::int64_t next_query[max_queries];
    for (std::size_t query = 0; query < query_count; ++query)
        high[query] = static_cast<std::int64_t>(event_count) + 1;

    for (;;) {
        std::int64_t heads[max_events + 1];
        for (std::size_t time = 0; time <= max_events; ++time) heads[time] = -1;
        for (std::size_t query = 0; query < query_count; ++query) next_query[query] = -1;
        bool active = false;
        for (std::size_t query = 0; query < query_count; ++query) {
            if (high[query] - low[query] > 1) {
                active = true;
                const auto middle = static_cast<std::size_t>((low[query] + high[query]) / 2);
                next_query[query] = heads[middle];
                heads[middle] = static_cast<std::int64_t>(query);
            }
        }
        if (!active) break;

        std::int64_t bit1[max_n + 2] = {};
        std::int64_t bit2[max_n + 2] = {};
        std::size_t applied = 0;
        for (std::size_t middle = 0; middle <= event_count; ++middle) {
            while (applied < middle) {
                range_add(bit1, bit2, n, static_cast<std::size_t>(event_left[applied]),
                          static_cast<std::size_t>(event_right[applied]), event_delta[applied]);
                ++applied;
            }
            auto query = heads[middle];
            while (query >= 0) {
                const auto id = static_cast<std::size_t>(query);
                if (range_sum(bit1, bit2, static_cast<std::size_t>(query_left[id]),
                              static_cast<std::size_t>(query_right[id])) >= query_target[id])
                    high[id] = static_cast<std::int64_t>(middle);
                else
                    low[id] = static_cast<std::int64_t>(middle);
                query = next_query[id];
            }
        }
    }

    std::int64_t result = 0;
    for (std::size_t query = 0; query < query_count; ++query)
        result += static_cast<std::int64_t>(query + 1) * (high[query] + 1);
    return result;
}
}  // namespace

extern "C" std::int64_t parallel_binary_search_range_threshold(
    const std::int64_t* input, std::size_t length) noexcept {
    return solve(input, length);
}
