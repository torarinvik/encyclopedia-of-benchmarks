const MAX_PARSEABLE_INPUT_LENGTH: usize = 66;
const JAVA_INT_MIN: i64 = -2_147_483_648;
const JAVA_INT_MAX: i64 = 2_147_483_647;
const MAX_FINITE_EDGE_COST: i64 = 1000;

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
    while (left < right) {
        const value = cities[left];
        cities[left] = cities[right];
        cities[right] = value;
        left += 1;
        right -= 1;
    }
    return true;
}

export fn traveling_salesman(input_opt: ?[*]const i64, length: usize) i64 {
    const values = input_opt orelse return -1;
    if (length < 1 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const city_count_value = values[0];
    if (city_count_value < 0 or city_count_value > 8) return -1;
    const city_count: usize = @intCast(city_count_value);
    if (length != 1 + city_count * city_count) return -1;

    var distances = [_]i64{0} ** 64;
    for (0..city_count * city_count) |index| {
        const value = values[1 + index];
        if (value < JAVA_INT_MIN or value > JAVA_INT_MAX) return -1;
        distances[index] = value;
    }
    if (city_count <= 1) return 0;

    for (0..city_count) |row| {
        for (0..city_count) |column| {
            if (row == column) continue;
            const value = distances[row * city_count + column];
            if (value != JAVA_INT_MAX and (value < 0 or value > MAX_FINITE_EDGE_COST)) return -1;
        }
    }

    var cities = [_]usize{0} ** 7;
    for (0..city_count - 1) |index| cities[index] = index + 1;
    var best: i64 = JAVA_INT_MAX;
    while (true) {
        var previous: usize = 0;
        var cost: i64 = 0;
        var valid = true;
        for (cities[0 .. city_count - 1]) |city| {
            const edge = distances[previous * city_count + city];
            if (edge == JAVA_INT_MAX) {
                valid = false;
                break;
            }
            cost += edge;
            previous = city;
        }
        if (valid) {
            const return_edge = distances[previous * city_count];
            if (return_edge == JAVA_INT_MAX) {
                valid = false;
            } else {
                cost += return_edge;
            }
        }
        if (valid and cost < best) best = cost;
        if (!nextPermutation(cities[0 .. city_count - 1])) break;
    }
    return best;
}
