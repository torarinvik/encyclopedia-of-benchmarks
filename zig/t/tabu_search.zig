const MAX_CITIES: usize = 6;
const MAX_TOUR: usize = 7;
const MAX_NEIGHBORS: usize = 32;
const MAX_OUTPUT_BYTES: usize = 36;

fn storeI32Le(output: [*]u8, offset: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

fn routeCost(route: *const [MAX_TOUR]i32, route_len: usize,
    edge_cost: *const [MAX_CITIES * MAX_CITIES]i64) i64 {
    var cost: i64 = 0;
    for (0..route_len - 1) |i| {
        cost += edge_cost[@intCast(route[i] * 6 + route[i + 1])];
    }
    return cost;
}

export fn tabu_search(input: ?[*]const i64, input_length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 3 or input_length > 19) return -1;
    if (values[0] < 4 or values[0] > 6 or values[1] < 0 or values[1] > 8 or values[2] < 1 or values[2] > 3) return -1;
    if (values[0] == 4 and values[1] >= 2 and values[2] >= 2) return -1;
    const cities: usize = @intCast(values[0]);
    const iterations: usize = @intCast(values[1]);
    const tabu_size: usize = @intCast(values[2]);
    const edge_count = cities * (cities - 1) / 2;
    if (input_length != 3 + edge_count) return -1;
    var edge_cost = [_]i64{0} ** (MAX_CITIES * MAX_CITIES);
    var offset: usize = 3;
    for (0..cities) |left| {
        for (left + 1..cities) |right| {
            const weight = values[offset];
            if (weight < 1 or weight > 99) return -1;
            edge_cost[left * 6 + right] = weight;
            edge_cost[right * 6 + left] = weight;
            offset += 1;
        }
    }

    var solution = [_]i32{0} ** MAX_TOUR;
    var solution_len: usize = 0;
    var visited = [_]bool{false} ** MAX_CITIES;
    var current: usize = 0;
    while (!visited[current]) {
        var minimum: i64 = 10000;
        var best_node = current;
        for (0..cities) |node| {
            if (node != current and !visited[node]) {
                const weight = edge_cost[current * 6 + node];
                if (weight < minimum) {
                    minimum = weight;
                    best_node = node;
                }
            }
        }
        visited[current] = true;
        solution[solution_len] = @intCast(current);
        solution_len += 1;
        current = best_node;
    }
    solution[solution_len] = 0;
    solution_len += 1;
    var best_solution = solution;
    var best_cost = routeCost(&solution, solution_len, &edge_cost);

    var tabu = [_][2]i32{.{ 0, 0 }} ** 3;
    var tabu_count: usize = 0;
    for (0..iterations) |_| {
        var candidates = [_][MAX_TOUR]i32{[_]i32{0} ** MAX_TOUR} ** MAX_NEIGHBORS;
        var candidate_costs = [_]i64{0} ** MAX_NEIGHBORS;
        var candidate_count: usize = 0;
        for (1..solution_len - 1) |first| {
            for (1..solution_len - 1) |second| {
                if (first == second) continue;
                var candidate = solution;
                const temporary = candidate[first];
                candidate[first] = candidate[second];
                candidate[second] = temporary;
                var duplicate = false;
                for (0..candidate_count) |prior| {
                    var same = true;
                    for (0..solution_len) |i| if (candidates[prior][i] != candidate[i]) { same = false; };
                    if (same) { duplicate = true; break; }
                }
                if (!duplicate) {
                    candidates[candidate_count] = candidate;
                    candidate_costs[candidate_count] = routeCost(&candidate, solution_len, &edge_cost);
                    candidate_count += 1;
                }
            }
        }
        // Stable insertion sort by cost.
        for (1..candidate_count) |i| {
            var j = i;
            while (j > 0 and candidate_costs[j] < candidate_costs[j - 1]) : (j -= 1) {
                const cost_tmp = candidate_costs[j];
                candidate_costs[j] = candidate_costs[j - 1];
                candidate_costs[j - 1] = cost_tmp;
                const route_tmp = candidates[j];
                candidates[j] = candidates[j - 1];
                candidates[j - 1] = route_tmp;
            }
        }
        var selected: usize = 0;
        while (selected < candidate_count) : (selected += 1) {
            var difference: ?usize = null;
            for (0..solution_len) |i| {
                if (candidates[selected][i] != solution[i]) {
                    difference = i;
                    break;
                }
            }
            const diff = difference orelse continue;
            const exchange = [2]i32{ candidates[selected][diff], solution[diff] };
            var is_tabu = false;
            for (0..tabu_count) |i| {
                if ((tabu[i][0] == exchange[0] and tabu[i][1] == exchange[1]) or
                    (tabu[i][0] == exchange[1] and tabu[i][1] == exchange[0])) is_tabu = true;
            }
            if (is_tabu) continue;
            tabu[tabu_count] = exchange;
            tabu_count += 1;
            if (tabu_count >= tabu_size) {
                for (0..tabu_count - 1) |i| tabu[i] = tabu[i + 1];
                tabu_count -= 1;
            }
            solution = candidates[selected];
            if (candidate_costs[selected] < best_cost) {
                best_cost = candidate_costs[selected];
                best_solution = solution;
            }
            break;
        }
    }

    var staged = [_]u8{0} ** MAX_OUTPUT_BYTES;
    const word_count = solution_len + 2;
    storeI32Le(&staged, 0, @intCast(solution_len));
    for (0..solution_len) |i| storeI32Le(&staged, 4 * (i + 1), best_solution[i]);
    storeI32Le(&staged, 4 * (solution_len + 1), @intCast(best_cost));
    const output_bytes = word_count * 4;
    const out = output orelse return -2;
    if (output_capacity < output_bytes) return -2;
    @memcpy(out[0..output_bytes], staged[0..output_bytes]);
    return @intCast(output_bytes);
}
