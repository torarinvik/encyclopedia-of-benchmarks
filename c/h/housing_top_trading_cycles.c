#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { TTC_MAX_AGENTS = 8, TTC_MAX_INPUT = 66 };

int64_t housing_top_trading_cycles(const int64_t *input, size_t length) {
    if (input == NULL || length < 2u || length > TTC_MAX_INPUT) return -1;
    const int64_t n_value = input[0];
    if (n_value < 1 || n_value > TTC_MAX_AGENTS) return -1;
    const size_t n = (size_t)n_value;
    if (length != 1u + n * n) return -1;

    int64_t preference[TTC_MAX_AGENTS][TTC_MAX_AGENTS] = {{0}};
    for (size_t agent = 0; agent < n; ++agent) {
        bool seen[TTC_MAX_AGENTS] = {false};
        for (size_t rank = 0; rank < n; ++rank) {
            const int64_t house = input[1u + agent * n + rank];
            if (house < 0 || house >= n_value || seen[house]) return -1;
            seen[house] = true;
            preference[agent][rank] = house;
        }
    }

    bool remaining[TTC_MAX_AGENTS] = {false};
    int64_t allocation[TTC_MAX_AGENTS] = {0};
    for (size_t agent = 0; agent < n; ++agent) remaining[agent] = true;
    size_t remaining_count = n;

    while (remaining_count > 0) {
        int64_t choice[TTC_MAX_AGENTS] = {0};
        size_t successor[TTC_MAX_AGENTS] = {0};
        size_t state[TTC_MAX_AGENTS] = {0};
        size_t path_position[TTC_MAX_AGENTS] = {0};
        size_t path[TTC_MAX_AGENTS] = {0};
        bool cycle_member[TTC_MAX_AGENTS] = {false};

        for (size_t agent = 0; agent < n; ++agent) {
            if (!remaining[agent]) continue;
            bool found = false;
            for (size_t rank = 0; rank < n; ++rank) {
                const int64_t house = preference[agent][rank];
                if (remaining[house]) {
                    choice[agent] = house;
                    successor[agent] = (size_t)house;
                    found = true;
                    break;
                }
            }
            if (!found) return -1;
        }

        for (size_t start = 0; start < n; ++start) {
            if (!remaining[start] || state[start] != 0) continue;
            size_t path_length = 0;
            size_t current = start;
            while (state[current] == 0) {
                state[current] = 1;
                path_position[current] = path_length;
                path[path_length++] = current;
                current = successor[current];
            }
            if (state[current] == 1) {
                const size_t cycle_start = path_position[current];
                for (size_t index = cycle_start; index < path_length; ++index)
                    cycle_member[path[index]] = true;
            }
            for (size_t index = 0; index < path_length; ++index)
                state[path[index]] = 2;
        }

        size_t removed = 0;
        for (size_t agent = 0; agent < n; ++agent) {
            if (remaining[agent] && cycle_member[agent]) {
                allocation[agent] = choice[agent];
                remaining[agent] = false;
                --remaining_count;
                ++removed;
            }
        }
        if (removed == 0) return -1;
    }

    int64_t result = 0;
    for (size_t agent = 0; agent < n; ++agent)
        result += allocation[agent] << (3u * agent);
    return result + 1;
}
