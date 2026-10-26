const max_n: usize = 12;
const max_m: usize = 16;
const max_input: usize = 18;

fn storeI64LE(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn min_sum_set_cover_greedy(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > max_input) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const m64 = input[1];
    if (n64 < 1 or n64 > 12 or m64 < 1 or m64 > 16 or
        length != 2 + @as(usize, @intCast(m64))) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    var masks: [max_m]u64 = [_]u64{0} ** max_m;
    for (0..m) |set| {
        const raw = input[2 + set];
        if (raw <= 0 or @as(u64, @intCast(raw)) >= (@as(u64, 1) << @intCast(n))) return -1;
        masks[set] = @intCast(raw);
    }
    const output_bytes = 8 * (n + 1);
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    var covered: [max_m]bool = [_]bool{false} ** max_m;
    var used: [max_n]bool = [_]bool{false} ** max_n;
    var order: [max_n]i64 = [_]i64{0} ** max_n;
    var total_time: i64 = 0;
    for (1..n + 1) |slot| {
        var chosen: usize = 0;
        var best_count: i64 = -1;
        for (0..n) |element| {
            if (used[element]) continue;
            var count: i64 = 0;
            for (0..m) |set| {
                if (!covered[set] and (masks[set] & (@as(u64, 1) << @intCast(element))) != 0) count += 1;
            }
            if (count > best_count) { best_count = count; chosen = element; }
        }
        used[chosen] = true;
        order[slot - 1] = @intCast(chosen);
        for (0..m) |set| {
            if (!covered[set] and (masks[set] & (@as(u64, 1) << @intCast(chosen))) != 0) {
                covered[set] = true;
                total_time += @intCast(slot);
            }
        }
    }
    storeI64LE(output, 0, total_time);
    for (0..n) |i| storeI64LE(output, 8 * (i + 1), order[i]);
    return @intCast(output_bytes);
}
