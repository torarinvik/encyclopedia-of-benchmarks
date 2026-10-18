const MAX_CITIES: usize = 8;
const MAX_INPUT_VALUES: usize = 17;
const MAX_OUTPUT_VALUES: usize = 11;
const MAX_MASKS: usize = 256;
const INF_COST: f64 = 1.0e300;

export fn travelling_salesman_dynamic_programming(input: ?[*]const f64, input_length: usize,
    output: ?[*]f64, capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 5 or input_length > MAX_INPUT_VALUES) return -1;
    const n_value = values[0];
    if (!std.math.isFinite(n_value) or n_value < 2.0 or n_value > @as(f64, @floatFromInt(MAX_CITIES)) or @trunc(n_value) != n_value) return -1;
    const n: usize = @intFromFloat(n_value);
    if (input_length != 1 + 2 * n) return -1;

    var x = [_]f64{0.0} ** MAX_CITIES;
    var y = [_]f64{0.0} ** MAX_CITIES;
    for (0..n) |city| {
        const cx = values[1 + 2 * city];
        const cy = values[2 + 2 * city];
        if (!std.math.isFinite(cx) or !std.math.isFinite(cy) or cx < -16.0 or cx > 16.0 or cy < -16.0 or cy > 16.0 or
            @trunc(cx) != cx or @trunc(cy) != cy) return -1;
        x[city] = cx;
        y[city] = cy;
    }

    var distances = [_]f64{0.0} ** (MAX_CITIES * MAX_CITIES);
    for (0..n) |from| {
        for (0..n) |to| {
            const dx = x[to] - x[from];
            const dy = y[to] - y[from];
            distances[from * MAX_CITIES + to] = @sqrt(dx * dx + dy * dy);
        }
    }

    var dp = [_]f64{INF_COST} ** (MAX_MASKS * MAX_CITIES);
    dp[MAX_CITIES] = 0.0;
    const mask_count: usize = 1 << @intCast(n);
    for (0..mask_count) |mask| {
        for (0..n) |u| {
            if ((mask & (@as(usize, 1) << @intCast(u))) == 0) continue;
            const prefix = dp[mask * MAX_CITIES + u];
            for (0..n) |v| {
                const bit = @as(usize, 1) << @intCast(v);
                if ((mask & bit) != 0) continue;
                const next_mask = mask | bit;
                const candidate = prefix + distances[u * MAX_CITIES + v];
                if (candidate < dp[next_mask * MAX_CITIES + v]) dp[next_mask * MAX_CITIES + v] = candidate;
            }
        }
    }

    const final_mask = mask_count - 1;
    var minimum = INF_COST;
    var end_node = n;
    for (1..n) |u| {
        const candidate = dp[final_mask * MAX_CITIES + u] + distances[u * MAX_CITIES];
        if (minimum > candidate) {
            minimum = candidate;
            end_node = u;
        }
    }
    if (end_node == n) return -1;

    var reverse_path = [_]usize{0} ** (MAX_CITIES + 1);
    var path_length: usize = 0;
    var mask = final_mask;
    while (end_node != 0) {
        reverse_path[path_length] = end_node;
        path_length += 1;
        const previous_mask = mask ^ (@as(usize, 1) << @intCast(end_node));
        var found = false;
        for (0..n) |u| {
            if ((mask & (@as(usize, 1) << @intCast(u))) == 0) continue;
            if (dp[mask * MAX_CITIES + end_node] ==
                dp[previous_mask * MAX_CITIES + u] + distances[u * MAX_CITIES + end_node]) {
                mask = previous_mask;
                end_node = u;
                found = true;
                break;
            }
        }
        if (!found or path_length > MAX_CITIES) return -1;
    }
    reverse_path[path_length] = 0;
    path_length += 1;
    var left: usize = 0;
    var right = path_length - 1;
    while (left < right) : (left += 1) {
        const temporary = reverse_path[left];
        reverse_path[left] = reverse_path[right];
        reverse_path[right] = temporary;
        right -= 1;
    }
    reverse_path[path_length] = 0;
    path_length += 1;

    var staged = [_]f64{0.0} ** MAX_OUTPUT_VALUES;
    staged[0] = @floatFromInt(path_length);
    for (0..path_length) |index| staged[index + 1] = @floatFromInt(reverse_path[index]);
    staged[path_length + 1] = minimum;
    const output_size = path_length + 2;
    const out = output orelse return -2;
    if (capacity < output_size) return -2;
    for (0..output_size) |index| out[index] = staged[index];
    return @intCast(output_size);
}
