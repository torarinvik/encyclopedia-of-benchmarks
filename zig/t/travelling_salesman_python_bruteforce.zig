const std = @import("std");

const MAX_CITIES: usize = 8;
const COORDINATE_LIMIT: f64 = 16.0;

export fn travelling_salesman_python_bruteforce(input: [*c]const f64, input_len: usize,
                                                output: [*c]f64, output_capacity: usize) i64 {
    if (input == null or input_len < 3 or input_len > 17) return -1;
    const raw_count = input[0];
    if (!std.math.isFinite(raw_count) or raw_count < 2.0 or raw_count > 8.0 or raw_count != @floor(raw_count)) return -1;
    const city_count: usize = @intFromFloat(raw_count);
    if (input_len != 1 + 2 * city_count) return -1;

    var x: [MAX_CITIES]f64 = [_]f64{0.0} ** MAX_CITIES;
    var y: [MAX_CITIES]f64 = [_]f64{0.0} ** MAX_CITIES;
    for (0..city_count) |city| {
        x[city] = input[1 + 2 * city];
        y[city] = input[2 + 2 * city];
        if (!std.math.isFinite(x[city]) or !std.math.isFinite(y[city]) or
            @abs(x[city]) > COORDINATE_LIMIT or @abs(y[city]) > COORDINATE_LIMIT or
            x[city] != @floor(x[city]) or y[city] != @floor(y[city])) return -1;
    }

    const permutation_len = city_count - 1;
    var order: [MAX_CITIES - 1]usize = [_]usize{0} ** (MAX_CITIES - 1);
    var best_order: [MAX_CITIES - 1]usize = [_]usize{0} ** (MAX_CITIES - 1);
    for (0..permutation_len) |i| order[i] = i + 1;
    var best_distance: f64 = 1.0e300;
    while (true) {
        var total: f64 = 0.0;
        var previous: usize = 0;
        for (0..permutation_len + 1) |i| {
            const next: usize = if (i == permutation_len) 0 else order[i];
            const dx = x[next] - x[previous];
            const dy = y[next] - y[previous];
            total += @sqrt(dx * dx + dy * dy);
            previous = next;
        }
        if (total < best_distance) {
            best_distance = total;
            for (0..permutation_len) |i| best_order[i] = order[i];
        }

        var i = permutation_len;
        while (i > 1 and order[i - 2] >= order[i - 1]) : (i -= 1) {}
        if (i <= 1) break;
        const pivot = i - 2;
        var j = permutation_len - 1;
        while (order[j] <= order[pivot]) : (j -= 1) {}
        std.mem.swap(usize, &order[pivot], &order[j]);
        var left = i - 1;
        var right = permutation_len - 1;
        while (left < right) : ({ left += 1; right -= 1; }) {
            std.mem.swap(usize, &order[left], &order[right]);
        }
    }

    var result: [11]f64 = [_]f64{0.0} ** 11;
    const path_len = city_count + 1;
    result[0] = @floatFromInt(path_len);
    result[1] = 0.0;
    for (0..permutation_len) |i| result[2 + i] = @floatFromInt(best_order[i]);
    result[path_len] = 0.0;
    result[path_len + 1] = best_distance;
    const required = city_count + 3;
    if (output == null or output_capacity < required) return -2;
    for (0..required) |i| output[i] = result[i];
    return @intCast(required);
}
