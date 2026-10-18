const INVALID_RESULT: f64 = -1.0e300;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 67;
const MAX_CITIES: i64 = 8;

fn nextPermutation(cities: []usize) bool {
    if (cities.len < 2) return false;
    var pivot = cities.len - 1;
    while (pivot > 0 and cities[pivot - 1] >= cities[pivot]) : (pivot -= 1) {}
    if (pivot == 0) return false;
    const pivot_index = pivot - 1;
    var successor = cities.len - 1;
    while (cities[successor] <= cities[pivot_index]) : (successor -= 1) {}
    const temporary = cities[pivot_index];
    cities[pivot_index] = cities[successor];
    cities[successor] = temporary;
    var left = pivot;
    var right = cities.len - 1;
    while (left < right) : ({ left += 1; right -= 1; }) {
        const value = cities[left];
        cities[left] = cities[right];
        cities[right] = value;
    }
    return true;
}

export fn traveling_salesman_solver_brute_force(input_opt: ?[*]const i64, length: usize) f64 {
    const values = input_opt orelse return INVALID_RESULT;
    if (length < 2 or length > MAX_PARSEABLE_INPUT_LENGTH) return INVALID_RESULT;
    const selector = values[0];
    const city_count_value = values[1];
    if (city_count_value < 2 or city_count_value > MAX_CITIES) return INVALID_RESULT;
    const city_count: usize = @intCast(city_count_value);
    if (selector < 0 or selector > @as(i64, @intCast(city_count + 1)) or
        length != 2 + city_count * city_count) return INVALID_RESULT;

    var distances = [_]i64{0} ** 64;
    for (0..city_count * city_count) |index| {
        const value = values[2 + index];
        if (value < 0 or value > 1000) return INVALID_RESULT;
        distances[index] = value;
    }

    var cities = [_]usize{0} ** 7;
    for (0..city_count - 1) |index| cities[index] = index + 1;
    var best_distance: i64 = 9_223_372_036_854_775_807;
    var best_route = [_]usize{0} ** 9;
    while (true) {
        var route = [_]usize{0} ** 9;
        route[0] = 0;
        for (0..city_count - 1) |index| route[index + 1] = cities[index];
        route[city_count] = 0;

        var distance: i64 = 0;
        for (0..city_count) |edge_index| {
            const from = route[edge_index];
            const to = route[edge_index + 1];
            distance += distances[from * city_count + to];
        }
        if (distance < best_distance) {
            best_distance = distance;
            best_route = route;
        }
        if (!nextPermutation(cities[0 .. city_count - 1])) break;
    }

    if (selector == 0) return @floatFromInt(best_distance);
    return @floatFromInt(best_route[@intCast(selector - 1)]);
}
