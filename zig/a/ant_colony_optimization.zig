const ANT_LIMIT: usize = 64;
const ITERATION_LIMIT: usize = 64;
const INVALID_RESULT: f64 = -1.0e300;

fn cityDistance(cities: []const i64, first: usize, second: usize) f64 {
    const dx: f64 = @floatFromInt(cities[2 * first] - cities[2 * second]);
    const dy: f64 = @floatFromInt(cities[2 * first + 1] - cities[2 * second + 1]);
    return @sqrt(dx * dx + dy * dy);
}

fn nextRandomFraction(state: *i64) f64 {
    state.* = @rem(state.* * 48271, 2147483647);
    return @as(f64, @floatFromInt(state.*)) / 2147483647.0;
}

fn selectNextCity(current: usize, visited: [3]bool, cities: []const i64,
                  pheromones: []const f64, random_state: *i64) usize {
    var scores: [3]f64 = @splat(0.0);
    var total: f64 = 0.0;
    for (0..3) |city| {
        if (visited[city]) continue;
        const heuristic = 1.0 / cityDistance(cities, current, city);
        const squared = heuristic * heuristic;
        const fifth = squared * squared * heuristic;
        scores[city] = pheromones[3 * current + city] * fifth;
        total += scores[city];
    }
    const roll = nextRandomFraction(random_state) * total;
    var cumulative: f64 = 0.0;
    var fallback: usize = 0;
    for (0..3) |city| {
        if (visited[city]) continue;
        fallback = city;
        cumulative += scores[city];
        if (cumulative >= roll) return city;
    }
    return fallback;
}

export fn ant_colony_optimization(input: ?[*]const i64, length: usize) f64 {
    if (input == null or length != 8) return INVALID_RESULT;
    const values = input.?[0..length];
    if (values[0] < 1 or values[0] > ANT_LIMIT or values[1] < 1 or values[1] > ITERATION_LIMIT)
        return INVALID_RESULT;
    var cities: [6]i64 = undefined;
    for (0..6) |index| {
        cities[index] = values[index + 2];
        if (cities[index] < -100_000 or cities[index] > 100_000) return INVALID_RESULT;
    }
    for (0..3) |first| {
        for (0..first) |second| {
            if (cities[2 * first] == cities[2 * second] and cities[2 * first + 1] == cities[2 * second + 1])
                return INVALID_RESULT;
        }
    }

    const ant_count: usize = @intCast(values[0]);
    const iteration_count: usize = @intCast(values[1]);
    var pheromones: [9]f64 = @splat(1.0);
    var routes: [ANT_LIMIT][4]usize = undefined;
    var random_state: i64 = 1;
    var best_distance: f64 = 1.0e300;

    for (0..iteration_count) |_| {
        for (0..ant_count) |ant| {
            routes[ant][0] = 0;
            var current: usize = 0;
            var visited = [3]bool{ true, false, false };
            for (1..3) |step| {
                current = selectNextCity(current, visited, cities[0..], pheromones[0..], &random_state);
                routes[ant][step] = current;
                visited[current] = true;
            }
            routes[ant][3] = 0;
            var distance: f64 = 0.0;
            for (0..3) |edge| distance += cityDistance(cities[0..], routes[ant][edge], routes[ant][edge + 1]);
            if (distance < best_distance) best_distance = distance;
        }
        for (0..9) |index| pheromones[index] *= 0.7;
        for (0..ant_count) |ant| {
            var distance: f64 = 0.0;
            for (0..3) |edge| distance += cityDistance(cities[0..], routes[ant][edge], routes[ant][edge + 1]);
            const deposit = 10.0 / distance;
            for (0..3) |edge| {
                const from = routes[ant][edge];
                const to = routes[ant][edge + 1];
                pheromones[3 * from + to] += deposit;
                pheromones[3 * to + from] += deposit;
            }
        }
    }
    return best_distance;
}
