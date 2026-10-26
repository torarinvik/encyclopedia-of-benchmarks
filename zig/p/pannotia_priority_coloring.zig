const max_n: usize = 16;
const max_m: usize = 64;
const max_input: usize = 147;
const max_priority: i64 = 99_999_998;

fn storeI64LE(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn pannotia_priority_coloring(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > max_input) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const m64 = input[1];
    const mode64 = input[2];
    if (n64 < 1 or n64 > 16 or m64 < 0 or m64 > 64 or (mode64 != 0 and mode64 != 1) or
        length != 3 + @as(usize, @intCast(n64)) + 2 * @as(usize, @intCast(m64))) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    const mode: usize = @intCast(mode64);
    var adjacency: [max_n]u64 = [_]u64{0} ** max_n;
    var degree: [max_n]usize = [_]usize{0} ** max_n;
    var priority: [max_n]i64 = [_]i64{0} ** max_n;
    var color: [max_n]i64 = [_]i64{-1} ** max_n;
    var active: [max_n]bool = [_]bool{false} ** max_n;
    for (0..n) |v| {
        priority[v] = input[3 + v];
        if (priority[v] < 0 or priority[v] > max_priority) return -1;
        for (0..v) |prior| if (priority[prior] == priority[v]) { return -1; };
        active[v] = true;
    }
    for (0..m) |edge| {
        const u_value = input[3 + n + 2 * edge];
        const v_value = input[4 + n + 2 * edge];
        if (u_value < 0 or v_value <= u_value or v_value >= n64) return -1;
        const u: usize = @intCast(u_value);
        const v: usize = @intCast(v_value);
        const bit = @as(u64, 1) << @intCast(v);
        if (adjacency[u] & bit != 0) return -1;
        adjacency[u] |= bit;
        adjacency[v] |= @as(u64, 1) << @intCast(u);
        degree[u] += 1;
        degree[v] += 1;
    }
    for (0..n) |v| if (degree[v] == 1) { return -1; };
    const output_bytes = 8 * n;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    var current_color: i64 = 1;
    while (true) {
        var chosen: [max_n]bool = [_]bool{false} ** max_n;
        var chosen_count: usize = 0;
        for (0..n) |v| {
            if (!active[v]) continue;
            var maximum: i64 = -1;
            var minimum: i64 = 99_999_999;
            for (0..n) |u| {
                if (active[u] and adjacency[v] & (@as(u64, 1) << @intCast(u)) != 0) {
                    if (priority[u] > maximum) maximum = priority[u];
                    if (priority[u] < minimum) minimum = priority[u];
                }
            }
            if (priority[v] > maximum) { color[v] = current_color; chosen[v] = true; }
            if (mode == 1 and priority[v] < minimum) { color[v] = current_color + 1; chosen[v] = true; }
            if (chosen[v]) chosen_count += 1;
        }
        if (chosen_count == 0) return -1;
        for (0..n) |v| if (chosen[v]) { active[v] = false; };
        var remaining = false;
        for (0..n) |v| remaining = remaining or active[v];
        if (!remaining) break;
        current_color += if (mode == 1) 2 else 1;
    }
    for (0..n) |v| storeI64LE(output, 8 * v, color[v]);
    return @intCast(output_bytes);
}
