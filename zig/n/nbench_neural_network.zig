const Pattern = [35]f64{ 0, 1, 1, 1, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 0 };
const Target = [8]f64{ 0, 1, 0, 0, 1, 1, 1, 1 };

fn putI64(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| output[offset + b] = @truncate(bits >> @intCast(8 * b));
}

export fn nbench_neural_network(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length != 1) return -1;
    const passes = input[0];
    if (passes < 1 or passes > 8) return -1;
    if (output == null or capacity < 88) return -2;

    var mw: [8][35]f64 = @splat(@splat(0.0));
    var ow: [8][8]f64 = @splat(@splat(0.0));
    var mc: [8][35]f64 = @splat(@splat(0.0));
    var oc: [8][8]f64 = @splat(@splat(0.0));
    var mm: [8][35]f64 = @splat(@splat(0.0));
    var om: [8][8]f64 = @splat(@splat(0.0));
    var mout: [8]f64 = @splat(0.0);
    var oout: [8]f64 = @splat(0.0);

    for (0..8) |n| {
        for (0..35) |w| {
            const raw: i32 = @as(i32, @intCast((n * 17 + w * 7) % 101)) - 50;
            mw[n][w] = @as(f64, @floatFromInt(raw)) / 1000.0;
        }
    }
    for (0..8) |n| {
        for (0..8) |w| {
            const raw: i32 = @as(i32, @intCast((n * 13 + w * 5) % 71)) - 35;
            ow[n][w] = @as(f64, @floatFromInt(raw)) / 1000.0;
        }
    }

    const pass_count: usize = @intCast(passes);
    for (0..pass_count) |_| {
        for (0..8) |n| {
            for (0..35) |w| {
                mc[n][w] = mm[n][w];
                mm[n][w] = 0.0;
            }
        }
        for (0..8) |n| {
            for (0..8) |w| {
                oc[n][w] = om[n][w];
                om[n][w] = 0.0;
            }
        }
        // The upstream do_forward_pass calls do_mid_forward twice.
        for (0..2) |_| {
            for (0..8) |n| {
                var sum: f64 = 0.0;
                for (0..35) |w| sum += mw[n][w] * Pattern[w];
                mout[n] = 1.0 / (1.0 + @exp(-sum));
            }
        }
        for (0..8) |n| {
            var sum: f64 = 0.0;
            for (0..8) |w| sum += ow[n][w] * mout[w];
            oout[n] = 1.0 / (1.0 + @exp(-sum));
        }

        var oe: [8]f64 = @splat(0.0);
        var me: [8]f64 = @splat(0.0);
        for (0..8) |n| oe[n] = Target[n] - oout[n];
        for (0..8) |n| {
            var sum: f64 = 0.0;
            for (0..8) |i| sum += ow[i][n] * oe[i];
            me[n] = mout[n] * (1.0 - mout[n]) * sum;
        }
        for (0..8) |n| {
            for (0..8) |w| {
                var delta = 0.09 * oe[n] * mout[w];
                delta += 0.09 * oc[n][w];
                ow[n][w] += delta;
                om[n][w] += delta;
            }
        }
        for (0..8) |n| {
            for (0..35) |w| {
                var delta = 0.09 * me[n] * Pattern[w];
                delta += 0.09 * mc[n][w];
                mw[n][w] += delta;
                mm[n][w] += delta;
            }
        }
    }

    var result: [11]i64 = @splat(0);
    result[0] = passes;
    for (0..8) |n| result[n + 1] = @intFromFloat(oout[n] * 1_000_000.0);
    var mid_sum: f64 = 0.0;
    var out_sum: f64 = 0.0;
    for (0..8) |n| for (0..35) |w| mid_sum += mw[n][w];
    for (0..8) |n| for (0..8) |w| out_sum += ow[n][w];
    result[9] = @intFromFloat(mid_sum * 1_000_000.0);
    result[10] = @intFromFloat(out_sum * 1_000_000.0);
    for (0..11) |i| putI64(output, i * 8, result[i]);
    return 88;
}
