// Clean-room bounded GBBS SCAN profile; see package LICENSE.txt.
const max_n: usize = 16;
const max_m: usize = 64;
const max_input: usize = 130;

fn similarityParts(u: usize, v: usize, adjacent: *const [max_n][max_n]bool,
    degree: *const [max_n]usize) struct { numerator: u64, denominator_sq: u64 } {
    var shared: u64 = 0;
    for (0..max_n) |w| {
        if (adjacent[u][w] and adjacent[v][w]) shared += 1;
    }
    return .{
        .numerator = shared + 2,
        .denominator_sq = @intCast((degree[u] + 1) * (degree[v] + 1)),
    };
}
fn epsilonSimilar(numerator: u64, denominator_sq: u64) bool {
    return 4 * numerator * numerator >= denominator_sq;
}
fn storeI64LE(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn gbbs_scan_structural_clustering(input_opt: ?[*]const i64, length: usize,
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
    var degree: [max_n]usize = [_]usize{0} ** max_n;
    for (0..m) |edge| {
        const u64 = input[2 + 2 * edge];
        const v64 = input[3 + 2 * edge];
        if (u64 < 0 or v64 <= u64 or v64 >= n64) return -1;
        const u: usize = @intCast(u64);
        const v: usize = @intCast(v64);
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = true;
        adjacent[v][u] = true;
        degree[u] += 1;
        degree[v] += 1;
    }
    const output_bytes = 8 * n;
    if (output_opt == null or capacity < output_bytes) return -2;
    var core: [max_n]bool = [_]bool{false} ** max_n;
    var labels: [max_n]i64 = [_]i64{-1} ** max_n;
    for (0..n) |u| {
        var similar_count: usize = 0;
        for (0..n) |v| {
            if (!adjacent[u][v]) continue;
            const score = similarityParts(u, v, &adjacent, &degree);
            if (epsilonSimilar(score.numerator, score.denominator_sq)) similar_count += 1;
        }
        core[u] = similar_count >= 2;
    }
    for (0..n) |root| {
        if (!core[root] or labels[root] != -1) continue;
        var queue: [max_n]usize = [_]usize{0} ** max_n;
        var head: usize = 0;
        var tail: usize = 1;
        labels[root] = @intCast(root);
        queue[0] = root;
        while (head < tail) {
            const u = queue[head];
            head += 1;
            for (0..n) |v| {
                if (!core[v] or labels[v] != -1 or !adjacent[u][v]) continue;
                const score = similarityParts(u, v, &adjacent, &degree);
                if (epsilonSimilar(score.numerator, score.denominator_sq)) {
                    labels[v] = @intCast(root);
                    queue[tail] = v;
                    tail += 1;
                }
            }
        }
    }
    for (0..n) |u| {
        if (core[u]) continue;
        var best_core: usize = max_n;
        var best_num: u64 = 0;
        var best_den: u64 = 1;
        for (0..n) |v| {
            if (!core[v] or !adjacent[u][v]) continue;
            const score = similarityParts(u, v, &adjacent, &degree);
            if (!epsilonSimilar(score.numerator, score.denominator_sq)) continue;
            const left = score.numerator * score.numerator * best_den;
            const right = best_num * best_num * score.denominator_sq;
            if (best_core == max_n or left > right or (left == right and v < best_core)) {
                best_core = v;
                best_num = score.numerator;
                best_den = score.denominator_sq;
            }
        }
        if (best_core != max_n) labels[u] = labels[best_core];
    }
    const output = output_opt.?;
    for (0..n) |v| storeI64LE(output, 8 * v, labels[v]);
    return @intCast(output_bytes);
}
