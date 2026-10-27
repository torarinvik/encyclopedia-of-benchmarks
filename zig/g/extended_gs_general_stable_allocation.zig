const max_input: usize = 19;
const max_output_bytes: usize = 104;
const inf: i64 = 255;

fn utility(first: i64, second: i64, count: i64) i64 {
    if (count == 0) return 0;
    if (count == 1) return first;
    return first + second;
}

fn chooseMen(men: usize, women: usize, quota: i64, edges: usize,
    mf: [4]i64, ms: [4]i64, lower: [4]i64, upper: [4]i64) [4]i64 {
    var answer: [4]i64 = @splat(0);
    var best_value: i64 = -1;
    var codes: usize = 1;
    for (0..edges) |_| codes *= 3;
    for (0..codes) |code| {
        var candidate: [4]i64 = @splat(0);
        var remainder = code;
        var e = edges;
        while (e > 0) { e -= 1; candidate[e] = @intCast(remainder % 3); remainder /= 3; }
        var feasible = true;
        for (0..edges) |edge| if (candidate[edge] < lower[edge] or candidate[edge] > upper[edge]) { feasible = false; };
        for (0..men) |man| {
            var total: i64 = 0;
            for (0..women) |woman| total += candidate[man * women + woman];
            if (total > quota) feasible = false;
        }
        if (!feasible) continue;
        var value: i64 = 0;
        for (0..edges) |edge| value += utility(mf[edge], ms[edge], candidate[edge]);
        if (value > best_value) { best_value = value; for (0..edges) |edge| answer[edge] = candidate[edge]; }
    }
    return answer;
}

fn chooseWomen(men: usize, women: usize, quota: i64, edges: usize,
    wf: [4]i64, ws: [4]i64, upper: [4]i64) [4]i64 {
    var answer: [4]i64 = @splat(0);
    var best_value: i64 = -1;
    var codes: usize = 1;
    for (0..edges) |_| codes *= 3;
    for (0..codes) |code| {
        var candidate: [4]i64 = @splat(0);
        var remainder = code;
        var e = edges;
        while (e > 0) { e -= 1; candidate[e] = @intCast(remainder % 3); remainder /= 3; }
        var feasible = true;
        for (0..edges) |edge| if (candidate[edge] > upper[edge]) { feasible = false; };
        for (0..women) |woman| {
            var total: i64 = 0;
            for (0..men) |man| total += candidate[man * women + woman];
            if (total > quota) feasible = false;
        }
        if (!feasible) continue;
        var value: i64 = 0;
        for (0..edges) |edge| value += utility(wf[edge], ws[edge], candidate[edge]);
        if (value > best_value) { best_value = value; for (0..edges) |edge| answer[edge] = candidate[edge]; }
    }
    return answer;
}

fn storeI64LE(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn extended_gs_general_stable_allocation(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > max_input) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > 2 or input[1] < 1 or input[1] > 2 or input[2] < 1 or input[2] > 2) return -1;
    const men: usize = @intCast(input[0]);
    const women: usize = @intCast(input[1]);
    const quota = input[2];
    const edges = men * women;
    if (length != 3 + 4 * edges) return -1;
    var mf: [4]i64 = @splat(0); var ms: [4]i64 = @splat(0);
    var wf: [4]i64 = @splat(0); var ws: [4]i64 = @splat(0);
    for (0..edges) |edge| {
        mf[edge] = input[3 + 4 * edge]; ms[edge] = input[4 + 4 * edge];
        wf[edge] = input[5 + 4 * edge]; ws[edge] = input[6 + 4 * edge];
        if (mf[edge] < 0 or mf[edge] > 8 or ms[edge] < 0 or ms[edge] > mf[edge]
            or wf[edge] < 0 or wf[edge] > 8 or ws[edge] < 0 or ws[edge] > wf[edge]) return -1;
    }
    var x_w: [4]i64 = @splat(0); var z_m: [4]i64 = @splat(inf); var z_w: [4]i64 = @splat(0);
    var x_m: [4]i64 = @splat(0); var next_w: [4]i64 = @splat(0);
    var converged = false;
    for (0..3 * edges + 2) |_| {
        x_m = chooseMen(men, women, quota, edges, mf, ms, x_w, z_m);
        next_w = chooseWomen(men, women, quota, edges, wf, ws, x_m);
        converged = true;
        for (0..edges) |edge| if (x_m[edge] != next_w[edge]) { converged = false; };
        if (converged) break;
        for (0..edges) |edge| {
            if (x_m[edge] > next_w[edge]) { z_m[edge] = next_w[edge]; z_w[edge] = inf; }
            x_w[edge] = next_w[edge];
        }
    }
    if (!converged) return -1;
    const output_values = 1 + 3 * edges;
    const output_bytes = 8 * output_values;
    if (output_opt == null or capacity < output_bytes) return -2;
    var staged: [max_output_bytes]u8 = @splat(0);
    storeI64LE(&staged, 0, @intCast(edges));
    for (0..edges) |edge| {
        storeI64LE(&staged, 8 * (1 + edge), x_m[edge]);
        storeI64LE(&staged, 8 * (1 + edges + edge), z_m[edge]);
        storeI64LE(&staged, 8 * (1 + 2 * edges + edge), @max(z_w[edge], x_m[edge]));
    }
    const output = output_opt.?;
    for (0..output_bytes) |byte| output[byte] = staged[byte];
    return @intCast(output_bytes);
}
