const max_n: usize = 16;
const max_m: usize = 64;
const max_input: usize = 146;
const max_priority: i64 = 99_999_998;

fn storeI64LE(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn pannotia_local_minimum_mis(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > max_input) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const m64 = input[1];
    if (n64 < 1 or n64 > 16 or m64 < 0 or m64 > 64 or
        length != 2 + @as(usize, @intCast(n64)) + 2 * @as(usize, @intCast(m64))) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    var adjacency: [max_n]u64 = [_]u64{0} ** max_n;
    var priority: [max_n]i64 = [_]i64{0} ** max_n;
    for (0..n) |v| {
        priority[v] = input[2 + v];
        if (priority[v] < 0 or priority[v] > max_priority) return -1;
        for (0..v) |prior| if (priority[prior] == priority[v]) { return -1; };
    }
    for (0..m) |edge| {
        const u_value = input[2 + n + 2 * edge];
        const v64 = input[3 + n + 2 * edge];
        if (u_value < 0 or v64 <= u_value or v64 >= n64) return -1;
        const u: usize = @intCast(u_value);
        const v: usize = @intCast(v64);
        const bit = @as(u64, 1) << @intCast(v);
        if (adjacency[u] & bit != 0) return -1;
        adjacency[u] |= bit;
        adjacency[v] |= @as(u64, 1) << @intCast(u);
    }
    const output_bytes = 8 * n;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    var active: [max_n]bool = [_]bool{false} ** max_n;
    var selected: [max_n]bool = [_]bool{false} ** max_n;
    for (0..n) |v| active[v] = true;
    while (true) {
        var chosen: [max_n]bool = [_]bool{false} ** max_n;
        var chosen_count: usize = 0;
        for (0..n) |v| {
            if (!active[v]) continue;
            var local_minimum = true;
            for (0..n) |u| {
                if (active[u] and adjacency[v] & (@as(u64, 1) << @intCast(u)) != 0 and priority[u] < priority[v]) local_minimum = false;
            }
            if (local_minimum) { chosen[v] = true; chosen_count += 1; }
        }
        if (chosen_count == 0) return -1;
        for (0..n) |v| if (chosen[v]) { selected[v] = true; active[v] = false; };
        for (0..n) |v| {
            if (!chosen[v]) continue;
            for (0..n) |u| if (active[u] and adjacency[v] & (@as(u64, 1) << @intCast(u)) != 0) { active[u] = false; };
        }
        var remaining = false;
        for (0..n) |v| remaining = remaining or active[v];
        if (!remaining) break;
    }
    for (0..n) |v| storeI64LE(output, 8 * v, if (selected[v]) 2 else 0);
    return @intCast(output_bytes);
}
