const INVALID_RESULT: f64 = -1.0e300;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 68;
const MAX_CITIES: i64 = 8;

export fn traveling_salesman_solver_nearest_neighbor(input_opt: ?[*]const i64, length: usize) f64 {
    const values = input_opt orelse return INVALID_RESULT;
    if (length < 3 or length > MAX_PARSEABLE_INPUT_LENGTH) return INVALID_RESULT;
    const selector = values[0];
    const city_count_value = values[1];
    const start_value = values[2];
    if (city_count_value < 1 or city_count_value > MAX_CITIES) return INVALID_RESULT;
    const city_count: usize = @intCast(city_count_value);
    if (selector < 0 or selector > @as(i64, @intCast(city_count + 1)) or
        start_value < 0 or start_value >= city_count_value or
        length != 3 + city_count * city_count) return INVALID_RESULT;

    var distances = [_]i64{0} ** 64;
    for (0..city_count * city_count) |index| {
        const value = values[3 + index];
        if (value < 0 or value > 1000) return INVALID_RESULT;
        distances[index] = value;
    }

    const start: usize = @intCast(start_value);
    var route = [_]usize{0} ** 9;
    var visited = [_]bool{false} ** 8;
    route[0] = start;
    visited[start] = true;
    var current = start;
    var total_distance: i64 = 0;
    for (0..city_count - 1) |step| {
        var next_city: ?usize = null;
        var minimum_distance: i64 = 1001;
        for (0..city_count) |city| {
            if (!visited[city]) {
                const distance = distances[current * city_count + city];
                if (distance < minimum_distance) {
                    minimum_distance = distance;
                    next_city = city;
                }
            }
        }
        const next = next_city orelse return INVALID_RESULT;
        route[step + 1] = next;
        visited[next] = true;
        total_distance += minimum_distance;
        current = next;
    }
    route[city_count] = start;
    total_distance += distances[current * city_count + start];

    if (selector == 0) return @floatFromInt(total_distance);
    return @floatFromInt(route[@intCast(selector - 1)]);
}
