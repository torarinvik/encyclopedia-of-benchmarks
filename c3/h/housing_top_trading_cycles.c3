module housing_top_trading_cycles;

const usz TTC_MAX_AGENTS = 8;
const usz TTC_MAX_INPUT = 66;

fn long housing_top_trading_cycles(long* input, usz length)
        @export("housing_top_trading_cycles") {
    if (input == null || length < 2 || length > TTC_MAX_INPUT) return -1;
    long n_value = input[0];
    if (n_value < 1 || n_value > (long)TTC_MAX_AGENTS) return -1;
    usz n = (usz)n_value;
    if (length != 1 + n * n) return -1;

    long[TTC_MAX_AGENTS][TTC_MAX_AGENTS] preference = zeroed;
    for (usz agent = 0; agent < n; agent += 1) {
        bool[TTC_MAX_AGENTS] seen = zeroed;
        for (usz rank = 0; rank < n; rank += 1) {
            long house = input[1 + agent * n + rank];
            if (house < 0 || house >= n_value || seen[(usz)house]) return -1;
            seen[(usz)house] = true;
            preference[agent][rank] = house;
        }
    }

    bool[TTC_MAX_AGENTS] remaining = zeroed;
    long[TTC_MAX_AGENTS] allocation = zeroed;
    for (usz agent = 0; agent < n; agent += 1) remaining[agent] = true;
    usz remaining_count = n;

    while (remaining_count > 0) {
        long[TTC_MAX_AGENTS] choice = zeroed;
        usz[TTC_MAX_AGENTS] successor = zeroed;
        usz[TTC_MAX_AGENTS] state = zeroed;
        usz[TTC_MAX_AGENTS] path_position = zeroed;
        usz[TTC_MAX_AGENTS] path = zeroed;
        bool[TTC_MAX_AGENTS] cycle_member = zeroed;

        for (usz agent = 0; agent < n; agent += 1) {
            if (!remaining[agent]) continue;
            bool found = false;
            for (usz rank = 0; rank < n; rank += 1) {
                long house = preference[agent][rank];
                if (remaining[(usz)house]) {
                    choice[agent] = house;
                    successor[agent] = (usz)house;
                    found = true;
                    break;
                }
            }
            if (!found) return -1;
        }

        for (usz start = 0; start < n; start += 1) {
            if (!remaining[start] || state[start] != 0) continue;
            usz path_length = 0;
            usz current = start;
            while (state[current] == 0) {
                state[current] = 1;
                path_position[current] = path_length;
                path[path_length] = current;
                path_length += 1;
                current = successor[current];
            }
            if (state[current] == 1) {
                usz cycle_start = path_position[current];
                for (usz index = cycle_start; index < path_length; index += 1)
                    cycle_member[path[index]] = true;
            }
            for (usz index = 0; index < path_length; index += 1)
                state[path[index]] = 2;
        }

        usz removed = 0;
        for (usz agent = 0; agent < n; agent += 1) {
            if (remaining[agent] && cycle_member[agent]) {
                allocation[agent] = choice[agent];
                remaining[agent] = false;
                remaining_count -= 1;
                removed += 1;
            }
        }
        if (removed == 0) return -1;
    }

    long result = 0;
    for (usz agent = 0; agent < n; agent += 1)
        result += allocation[agent] << (3 * agent);
    return result + 1;
}
