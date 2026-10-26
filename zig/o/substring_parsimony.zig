const MAX_STATES: usize = 4;
const MAX_INPUT: usize = 26;
const MAX_ASSIGNMENTS: usize = 1024;
const MAX_OUTPUT_WORDS: usize = 2 + 5 * MAX_ASSIGNMENTS;
const INF: i64 = 1_000_000;

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn substring_parsimony(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 10 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const q_raw = input[0];
    const threshold = input[1];
    if (q_raw < 1 or q_raw > MAX_STATES or threshold < 0 or threshold > 36) return -1;
    const q: usize = @intCast(q_raw);
    if (length != 9 + q * q) return -1;
    const child = [2][2]i64{ .{ input[2], input[3] }, .{ input[4], input[5] } };
    for (0..2) |node| {
        if (child[node][0] < 1 or child[node][0] > 4 or child[node][1] < 1 or child[node][1] > 4
            or child[node][0] == child[node][1]) return -1;
    }
    const root_leaf: i64 = if (child[0][0] == 1) child[0][1]
        else if (child[0][1] == 1) child[0][0] else -1;
    if (root_leaf < 2 or root_leaf > 4) return -1;
    if (child[1][0] < 2 or child[1][0] > 4 or child[1][1] < 2 or child[1][1] > 4
        or child[1][0] == child[1][1] or child[1][0] == root_leaf or child[1][1] == root_leaf) return -1;
    for (2..5) |leaf| {
        if (@as(i64, @intCast(leaf)) != root_leaf and child[1][0] != @as(i64, @intCast(leaf))
            and child[1][1] != @as(i64, @intCast(leaf))) return -1;
    }
    const masks = [3]i64{ input[6], input[7], input[8] };
    const universe = (@as(u64, 1) << @intCast(q)) - 1;
    for (0..3) |leaf| {
        if (masks[leaf] <= 0 or @as(u64, @intCast(masks[leaf])) > universe) return -1;
    }
    var distance: [MAX_STATES][MAX_STATES]i64 = undefined;
    for (0..q) |i| {
        for (0..q) |j| {
            const value = input[9 + i * q + j];
            if (value < 0 or value > 9 or (i == j and value != 0) or (i != j and value == 0)) return -1;
            distance[i][j] = value;
            if (value != input[9 + j * q + i]) return -1;
        }
    }
    for (0..q) |i| {
        for (0..q) |j| {
            for (0..q) |k| {
                if (distance[i][k] > distance[i][j] + distance[j][k]) return -1;
            }
        }
    }
    var dp: [5][MAX_STATES]i64 = undefined;
    for (0..5) |node| for (0..q) |state| { dp[node][state] = INF; };
    for (2..5) |leaf| {
        for (0..q) |state| {
            if (@as(u64, @intCast(masks[leaf - 2])) & (@as(u64, 1) << @intCast(state)) != 0)
                dp[leaf][state] = 0;
        }
    }
    var node: isize = 1;
    while (node >= 0) : (node -= 1) {
        const n: usize = @intCast(node);
        for (0..q) |state| {
            var total: i64 = 0;
            for (0..2) |slot| {
                const descendant: usize = @intCast(child[n][slot]);
                var best = INF;
                for (0..q) |other| {
                    const candidate = dp[descendant][other] + distance[state][other];
                    if (candidate < best) best = candidate;
                }
                total += best;
            }
            dp[n][state] = total;
        }
    }
    var optimum = INF;
    for (0..q) |state| if (dp[0][state] < optimum) { optimum = dp[0][state]; };
    if (optimum >= INF) return -1;
    var staged: [MAX_OUTPUT_WORDS]i64 = @splat(0);
    staged[0] = optimum;
    var words: usize = 2;
    if (optimum <= threshold) {
        for (0..q) |x0| {
            for (0..q) |x1| {
                for (0..q) |x2| {
                    if (@as(u64, @intCast(masks[0])) & (@as(u64, 1) << @intCast(x2)) == 0) continue;
                    for (0..q) |x3| {
                        if (@as(u64, @intCast(masks[1])) & (@as(u64, 1) << @intCast(x3)) == 0) continue;
                        for (0..q) |x4| {
                            if (@as(u64, @intCast(masks[2])) & (@as(u64, 1) << @intCast(x4)) == 0) continue;
                            const label = [5]usize{ x0, x1, x2, x3, x4 };
                            var score: i64 = 0;
                            for (0..2) |parent| {
                                for (0..2) |slot| {
                                    const descendant: usize = @intCast(child[parent][slot]);
                                    score += distance[label[parent]][label[descendant]];
                                }
                            }
                            if (score == optimum) {
                                for (0..5) |vertex| {
                                    staged[words] = @intCast(label[vertex]);
                                    words += 1;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    staged[1] = @intCast((words - 2) / 5);
    const bytes = words * 8;
    if (output_opt == null or capacity < bytes) return -2;
    const output = output_opt.?;
    for (0..words) |word| storeI64Le(output, word * 8, staged[word]);
    return @intCast(bytes);
}
