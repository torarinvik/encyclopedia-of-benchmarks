const N: usize = 8;
const MAX_EDGES: usize = 28;
const MAX_INPUT: usize = 58;
const MAX_OUTPUT: usize = 72;

fn putI64(out: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| out[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn treewidth_exact_elimination_order(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > 8 or input[1] < 0 or input[1] > 28) return -1;
    const n: usize = @intCast(input[0]);
    const m: usize = @intCast(input[1]);
    if (m > n * (n - 1) / 2 or length != 2 + 2 * m) return -1;
    var base: [N][N]bool = @splat(@splat(false));
    for (0..m) |edge| {
        const a0 = input[2 + 2 * edge];
        const b0 = input[3 + 2 * edge];
        if (a0 < 0 or b0 < 0 or a0 >= @as(i64, @intCast(n)) or b0 >= @as(i64, @intCast(n)) or a0 >= b0) return -1;
        const a: usize = @intCast(a0);
        const b: usize = @intCast(b0);
        if (base[a][b]) return -1;
        base[a][b] = true;
        base[b][a] = true;
    }
    var permutation: [N]usize = @splat(0);
    var best_order: [N]usize = @splat(0);
    for (0..n) |i| permutation[i] = i;
    var best_width: usize = N + 1;
    while (true) {
        var adjacent = base;
        var active: [N]bool = @splat(false);
        for (0..n) |i| active[i] = true;
        var width: usize = 0;
        for (0..n) |step| {
            const vertex = permutation[step];
            var neighbors: [N]usize = @splat(0);
            var count: usize = 0;
            for (0..n) |other| if (active[other] and adjacent[vertex][other]) {
                neighbors[count] = other;
                count += 1;
            };
            width = @max(width, count);
            for (0..count) |i| {
                for (i + 1..count) |j| {
                    const a = neighbors[i];
                    const b = neighbors[j];
                    adjacent[a][b] = true;
                    adjacent[b][a] = true;
                }
            }
            active[vertex] = false;
        }
        if (width < best_width) {
            best_width = width;
            @memcpy(best_order[0..n], permutation[0..n]);
        }
        var pivot = n;
        while (pivot > 1 and permutation[pivot - 2] >= permutation[pivot - 1]) : (pivot -= 1) {}
        if (pivot <= 1) break;
        const pivot_index = pivot - 2;
        var successor = n - 1;
        while (permutation[successor] <= permutation[pivot_index]) : (successor -= 1) {}
        const temp = permutation[pivot_index];
        permutation[pivot_index] = permutation[successor];
        permutation[successor] = temp;
        var left = pivot_index + 1;
        var right = n - 1;
        while (left < right) : ({ left += 1; right -= 1; }) {
            const swap_value = permutation[left];
            permutation[left] = permutation[right];
            permutation[right] = swap_value;
        }
    }
    const bytes = 8 * (n + 1);
    if (output_opt == null or capacity < bytes) return -2;
    var staged: [MAX_OUTPUT]u8 = @splat(0);
    putI64(&staged, 0, @intCast(best_width));
    for (0..n) |i| putI64(&staged, 8 * (i + 1), @intCast(best_order[i]));
    @memcpy(output_opt.?[0..bytes], staged[0..bytes]);
    return @intCast(bytes);
}
