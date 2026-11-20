#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_agents = 8;
constexpr std::size_t max_input = 66;
}

extern "C" std::int64_t housing_top_trading_cycles(const std::int64_t *input,
                                                    std::size_t length) {
    if (input == nullptr || length < 2 || length > max_input) return -1;
    const auto n_value = input[0];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_agents)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    if (length != 1 + n * n) return -1;

    std::int64_t preference[max_agents][max_agents]{};
    for (std::size_t agent = 0; agent < n; ++agent) {
        bool seen[max_agents]{};
        for (std::size_t rank = 0; rank < n; ++rank) {
            const auto house = input[1 + agent * n + rank];
            if (house < 0 || house >= n_value || seen[house]) return -1;
            seen[house] = true;
            preference[agent][rank] = house;
        }
    }

    bool remaining[max_agents]{};
    std::int64_t allocation[max_agents]{};
    for (std::size_t agent = 0; agent < n; ++agent) remaining[agent] = true;
    auto remaining_count = n;

    while (remaining_count > 0) {
        std::int64_t choice[max_agents]{};
        std::size_t successor[max_agents]{};
        std::size_t state[max_agents]{};
        std::size_t path_position[max_agents]{};
        std::size_t path[max_agents]{};
        bool cycle_member[max_agents]{};

        for (std::size_t agent = 0; agent < n; ++agent) {
            if (!remaining[agent]) continue;
            bool found = false;
            for (std::size_t rank = 0; rank < n; ++rank) {
                const auto house = preference[agent][rank];
                if (remaining[house]) {
                    choice[agent] = house;
                    successor[agent] = static_cast<std::size_t>(house);
                    found = true;
                    break;
                }
            }
            if (!found) return -1;
        }

        for (std::size_t start = 0; start < n; ++start) {
            if (!remaining[start] || state[start] != 0) continue;
            std::size_t path_length = 0;
            auto current = start;
            while (state[current] == 0) {
                state[current] = 1;
                path_position[current] = path_length;
                path[path_length++] = current;
                current = successor[current];
            }
            if (state[current] == 1) {
                const auto cycle_start = path_position[current];
                for (std::size_t index = cycle_start; index < path_length; ++index)
                    cycle_member[path[index]] = true;
            }
            for (std::size_t index = 0; index < path_length; ++index)
                state[path[index]] = 2;
        }

        std::size_t removed = 0;
        for (std::size_t agent = 0; agent < n; ++agent) {
            if (remaining[agent] && cycle_member[agent]) {
                allocation[agent] = choice[agent];
                remaining[agent] = false;
                --remaining_count;
                ++removed;
            }
        }
        if (removed == 0) return -1;
    }

    std::int64_t result = 0;
    for (std::size_t agent = 0; agent < n; ++agent)
        result += allocation[agent] << (3 * agent);
    return result + 1;
}
