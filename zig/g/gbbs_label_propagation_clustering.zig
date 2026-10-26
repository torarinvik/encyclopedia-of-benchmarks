// Clean-room bounded GBBS label-propagation profile; see package LICENSE.txt.
const max_n: usize = 16;
const max_m: usize = 64;
const max_input: usize = 130;

fn storeI64LE(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn gbbs_label_propagation_clustering(input_opt: ?[*]const i64, length: usize,
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
    const output_bytes = 8 * n;
    if (output_opt == null or capacity < output_bytes) return -2;

    var labels: [max_n]i64 = [_]i64{0} ** max_n;
    for (0..n) |vertex| labels[vertex] = @intCast(vertex);
    for (0..n) |u| {
        var frequency: [max_n]usize = [_]usize{0} ** max_n;
        var degree: usize = 0;
        for (0..n) |v| {
            if (adjacent[u][v]) {
                frequency[@intCast(labels[v])] += 1;
                degree += 1;
            }
        }
        if (degree == 0) continue;
        var best_label: usize = 0;
        var best_frequency: usize = 0;
        for (0..n) |label| {
            if (frequency[label] > best_frequency or
                (frequency[label] == best_frequency and frequency[label] != 0 and label > best_label)) {
                best_label = label;
                best_frequency = frequency[label];
            }
        }
        labels[u] = @intCast(best_label);
    }
    const output = output_opt.?;
    for (0..n) |vertex| storeI64LE(output, 8 * vertex, labels[vertex]);
    return @intCast(output_bytes);
}
