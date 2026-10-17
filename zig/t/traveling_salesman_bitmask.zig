const MAX_CITIES: usize = 10;
const MAX_MASKS: usize = 1024;
const MAX_STATES: usize = MAX_CITIES * MAX_MASKS;
const MAX_INPUT_VALUES: usize = 102;
const MAX_DISTANCE: i64 = 1000;

fn solve(
    position: usize,
    mask: usize,
    city_count: usize,
    distances: []const i64,
    memo: []i64,
    seen: []bool,
) i64 {
    const all_visited = (@as(usize, 1) << @intCast(city_count)) - 1;
    if (mask == all_visited) return distances[position * city_count];
    const state = position * MAX_MASKS + mask;
    if (seen[state]) return memo[state];

    seen[state] = true;
    var best: i64 = 10001;
    for (0..city_count) |city| {
        const bit = @as(usize, 1) << @intCast(city);
        if ((mask & bit) == 0) {
            const cost = distances[position * city_count + city] +
                solve(city, mask | bit, city_count, distances, memo, seen);
            if (cost < best) best = cost;
        }
    }
    memo[state] = best;
    return best;
}

export fn traveling_salesman_bitmask(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > MAX_INPUT_VALUES) return -1;
    const values = input.?[0..length];
    const city_count_value = values[0];
    if (city_count_value < 2 or city_count_value > 10) return -1;
    const city_count: usize = @intCast(city_count_value);
    if (length != 1 + city_count * city_count) return -1;

    var distances: [MAX_CITIES * MAX_CITIES]i64 = @splat(0);
    for (0..city_count * city_count) |index| {
        const distance = values[1 + index];
        if (distance < 0 or distance > MAX_DISTANCE) return -1;
        if (index / city_count == index % city_count and distance != 0) return -1;
        distances[index] = distance;
    }

    var memo: [MAX_STATES]i64 = @splat(0);
    var seen: [MAX_STATES]bool = @splat(false);
    return solve(0, 1, city_count, distances[0 .. city_count * city_count],
        memo[0..], seen[0..]);
}
