const MAX_OBSERVATIONS: usize = 128;
const MAX_GROUPS: usize = 8;
const INVALID_RESULT: f64 = -1.0e300;

fn safeDenominator(value: f64) f64 {
    if (@abs(value) >= 1.0e-300) return value;
    return if (value < 0.0) -1.0e-300 else 1.0e-300;
}

fn logGammaLanczos(value: f64) f64 {
    const z = value - 1.0;
    var sum: f64 = 0.99999999999980993;
    sum += 676.5203681218851 / (z + 1.0);
    sum -= 1259.1392167224028 / (z + 2.0);
    sum += 771.32342877765313 / (z + 3.0);
    sum -= 176.61502916214059 / (z + 4.0);
    sum += 12.507343278686905 / (z + 5.0);
    sum -= 0.13857109526572012 / (z + 6.0);
    sum += 9.9843695780195716e-6 / (z + 7.0);
    sum += 1.5056327351493116e-7 / (z + 8.0);
    const t = z + 7.5;
    return 0.91893853320467274178 + (z + 0.5) * @log(t) - t + @log(sum);
}

fn betaFraction(a: f64, b: f64, x: f64) f64 {
    const qab = a + b;
    const qap = a + 1.0;
    const qam = a - 1.0;
    var c: f64 = 1.0;
    var d = safeDenominator(1.0 - qab * x / qap);
    d = 1.0 / d;
    var result = d;
    for (1..201) |m| {
        const md: f64 = @floatFromInt(m);
        const m2 = 2.0 * md;
        var coefficient = md * (b - md) * x / ((qam + m2) * (a + m2));
        d = safeDenominator(1.0 + coefficient * d);
        c = safeDenominator(1.0 + coefficient / c);
        d = 1.0 / d;
        result *= d * c;
        coefficient = -(a + md) * (qab + md) * x / ((a + m2) * (qap + m2));
        d = safeDenominator(1.0 + coefficient * d);
        c = safeDenominator(1.0 + coefficient / c);
        d = 1.0 / d;
        const change = d * c;
        result *= change;
        if (@abs(change - 1.0) <= 3.0e-14) break;
    }
    return result;
}

fn regularizedBeta(x: f64, a: f64, b: f64) f64 {
    if (x <= 0.0) return 0.0;
    if (x >= 1.0) return 1.0;
    const front = @exp(a * @log(x) + b * @log(1.0 - x) +
        logGammaLanczos(a + b) - logGammaLanczos(a) - logGammaLanczos(b));
    if (x < (a + 1.0) / (a + b + 2.0)) return front * betaFraction(a, b, x) / a;
    return 1.0 - front * betaFraction(b, a, 1.0 - x) / b;
}

export fn anova_oneway(input: ?[*]const i64, length: usize) f64 {
    if (input == null or length < 3) return INVALID_RESULT;
    const values = input.?[0..length];
    const statistic = values[0];
    const observation_count = values[1];
    const group_count = values[2];
    if (statistic < 0 or statistic > 7 or observation_count <= group_count or
        observation_count > MAX_OBSERVATIONS or group_count < 2 or group_count > MAX_GROUPS or
        length != 3 + 2 * @as(usize, @intCast(observation_count))) return INVALID_RESULT;

    const n: usize = @intCast(observation_count);
    const k: usize = @intCast(group_count);
    var group_sums: [MAX_GROUPS]f64 = @splat(0.0);
    var group_means: [MAX_GROUPS]f64 = @splat(0.0);
    var group_sizes: [MAX_GROUPS]i64 = @splat(0);
    var labels: [MAX_OBSERVATIONS]i64 = @splat(0);
    var total: f64 = 0.0;
    for (0..n) |i| {
        const value = values[3 + i];
        const group = values[3 + n + i];
        if (value < -1_000_000 or value > 1_000_000 or group < 0 or group >= group_count) return INVALID_RESULT;
        labels[i] = group;
        const group_index: usize = @intCast(group);
        group_sums[group_index] += @floatFromInt(value);
        group_sizes[group_index] += 1;
        total += @floatFromInt(value);
    }
    for (0..k) |group| {
        if (group_sizes[group] == 0) return INVALID_RESULT;
        group_means[group] = group_sums[group] / @as(f64, @floatFromInt(group_sizes[group]));
    }
    const grand_mean = total / @as(f64, @floatFromInt(n));
    var ss_between: f64 = 0.0;
    for (0..k) |group| {
        const difference = group_means[group] - grand_mean;
        ss_between += @as(f64, @floatFromInt(group_sizes[group])) * difference * difference;
    }
    var ss_within: f64 = 0.0;
    for (0..k) |group| {
        for (0..n) |i| {
            if (labels[i] == @as(i64, @intCast(group))) {
                const difference = @as(f64, @floatFromInt(values[3 + i])) - group_means[group];
                ss_within += difference * difference;
            }
        }
    }
    if (!(ss_within > 0.0)) return INVALID_RESULT;

    const df_between = @as(f64, @floatFromInt(group_count - 1));
    const df_within = @as(f64, @floatFromInt(observation_count - group_count));
    const ms_between = ss_between / df_between;
    const ms_within = ss_within / df_within;
    const f_statistic = ms_between / ms_within;
    const beta_x = df_within / (df_within + df_between * f_statistic);
    const p_value = regularizedBeta(beta_x, df_within / 2.0, df_between / 2.0);
    const outputs = [8]f64{ df_between, df_within, ss_between, ss_within, ms_between, ms_within, f_statistic, p_value };
    return outputs[@intCast(statistic)];
}
