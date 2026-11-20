const MAX_N: usize = 8;
const MAX_INPUT_LENGTH: usize = 66;

export fn housing_top_trading_cycles(input_opt: ?[*]const i64, length: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    const n_value = values[0];
    if (n_value < 1 or n_value > MAX_N) return -1;
    const n: usize = @intCast(n_value);
    if (length != 1 + n * n) return -1;

    var preferences: [MAX_N][MAX_N]usize = @splat(@splat(0));
    var cursor: usize = 1;
    for (0..n) |agent| {
        var seen: [MAX_N]bool = @splat(false);
        for (0..n) |rank| {
            const house_value = values[cursor];
            cursor += 1;
            if (house_value < 0 or house_value >= n_value) return -1;
            const house: usize = @intCast(house_value);
            if (seen[house]) return -1;
            seen[house] = true;
            preferences[agent][rank] = house;
        }
    }

    var agent_active: [MAX_N]bool = @splat(false);
    var house_active: [MAX_N]bool = @splat(false);
    var allocation: [MAX_N]usize = @splat(0);
    for (0..n) |index| {
        agent_active[index] = true;
        house_active[index] = true;
    }
    var active_count = n;
    while (active_count > 0) {
        var choice: [MAX_N]usize = @splat(0);
        for (0..n) |agent| {
            if (!agent_active[agent]) continue;
            var found = false;
            for (0..n) |rank| {
                const house = preferences[agent][rank];
                if (house_active[house]) {
                    choice[agent] = house;
                    found = true;
                    break;
                }
            }
            if (!found) return -1;
        }

        // Contract each agent -> chosen house -> owner pair into one agent edge.
        var state: [MAX_N]u8 = @splat(0);
        var path_position: [MAX_N]i32 = @splat(-1);
        var selected_this_round: [MAX_N]bool = @splat(false);
        var path: [MAX_N]usize = @splat(0);
        for (0..n) |start| {
            if (!agent_active[start] or state[start] != 0) continue;
            var current = start;
            var path_length: usize = 0;
            while (state[current] == 0) {
                state[current] = 1;
                path_position[current] = @intCast(path_length);
                path[path_length] = current;
                path_length += 1;
                current = choice[current];
            }
            if (state[current] == 1) {
                const cycle_start: usize = @intCast(path_position[current]);
                for (cycle_start..path_length) |index| {
                    selected_this_round[path[index]] = true;
                }
            }
            for (0..path_length) |index| {
                state[path[index]] = 2;
                path_position[path[index]] = -1;
            }
        }

        var removed: usize = 0;
        for (0..n) |agent| {
            if (selected_this_round[agent]) {
                allocation[agent] = choice[agent];
                agent_active[agent] = false;
                house_active[choice[agent]] = false;
                removed += 1;
            }
        }
        if (removed == 0) return -1;
        active_count -= removed;
    }

    var packed: i64 = 1;
    for (0..n) |agent| {
        packed += @as(i64, @intCast(allocation[agent])) << @intCast(3 * agent);
    }
    return packed;
}
