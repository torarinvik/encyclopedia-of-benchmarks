// Clean-room bounded GBBS five-cycle profile; see package LICENSE.txt.
const max_n: usize = 16;
const max_m: usize = 64;
const max_input: usize = 130;

fn storeI64LE(output: [*]u8, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn gbbs_five_cycle_count(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > max_input) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const m64 = input[1];
    if (n64 < 1 or n64 > 16 or m64 < 0 or m64 > 64) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    if (length != 2 + 2 * m) return -1;
    var adjacent: [max_n][max_n]bool = [_][max_n]bool{[_]bool{false} ** max_n} ** max_n;
    for (0..m) |edge| {
        const u64 = input[2 + 2 * edge];
        const v64 = input[3 + 2 * edge];
        if (u64 < 0 or v64 <= u64 or v64 >= n64) return -1;
        const u: usize = @intCast(u64);
        const v: usize = @intCast(v64);
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = true;
        adjacent[v][u] = true;
    }
    if (output_opt == null or capacity < 8) return -2;

    var count: i64 = 0;
    for (0..n) |start| {
        for (start + 1..n) |first| {
            for (start + 1..n) |second| {
                if (second == first) continue;
                for (start + 1..n) |third| {
                    if (third == first or third == second) continue;
                    for (first + 1..n) |last| {
                        if (last == second or last == third) continue;
                        if (adjacent[start][first] and adjacent[first][second] and
                            adjacent[second][third] and adjacent[third][last] and
                            adjacent[last][start]) count += 1;
                    }
                }
            }
        }
    }
    storeI64LE(output_opt.?, count);
    return 8;
}
