const std = @import("std");

const PI_VALUE: f64 = 3.14159265358979323846264338327950288;

fn qnorm_r_as241(probability: f64) f64 {
    const q = probability - 0.5;
    if (@abs(q) <= 0.425) {
        const r = 0.180625 - q * q;
        var numerator: f64 = 2509.0809287301226727;
        numerator = numerator * r + 33430.575583588128105;
        numerator = numerator * r + 67265.770927008700853;
        numerator = numerator * r + 45921.953931549871457;
        numerator = numerator * r + 13731.693765509461125;
        numerator = numerator * r + 1971.5909503065514427;
        numerator = numerator * r + 133.14166789178437745;
        numerator = numerator * r + 3.387132872796366608;
        var denominator: f64 = 5226.495278852854561;
        denominator = denominator * r + 28729.085735721942674;
        denominator = denominator * r + 39307.89580009271061;
        denominator = denominator * r + 21213.794301586595867;
        denominator = denominator * r + 5394.1960214247511077;
        denominator = denominator * r + 687.1870074920579083;
        denominator = denominator * r + 42.313330701600911252;
        denominator = denominator * r + 1.0;
        return q * numerator / denominator;
    }
    const r = @sqrt(-@log(1.0 - probability)) - 1.6;
    var numerator: f64 = 0.00077454501427834140764;
    numerator = numerator * r + 0.0227238449892691845833;
    numerator = numerator * r + 0.24178072517745061177;
    numerator = numerator * r + 1.27045825245236838258;
    numerator = numerator * r + 3.64784832476320460504;
    numerator = numerator * r + 5.7694972214606914055;
    numerator = numerator * r + 4.6303378461565452959;
    numerator = numerator * r + 1.42343711074968357734;
    var denominator: f64 = 1.05075007164441684324e-9;
    denominator = denominator * r + 0.0005475938084995344946;
    denominator = denominator * r + 0.0151986665636164571966;
    denominator = denominator * r + 0.14810397642748007459;
    denominator = denominator * r + 0.68976733498510000455;
    denominator = denominator * r + 1.6763848301838038494;
    denominator = denominator * r + 2.05319162663775882187;
    denominator = denominator * r + 1.0;
    return numerator / denominator;
}

export fn generate_risk_report(input: ?[*]const f64, input_length: usize,
    output: ?[*]f64, capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 24 or input_length > 69) return -1;
    for (0..input_length) |i| if (!std.math.isFinite(values[i])) return -1;
    const portfolio = values[0];
    const confidence = values[1];
    const horizon = values[2];
    const count_value = values[3];
    if (@trunc(count_value) != count_value or count_value < 20 or count_value > 64) return -1;
    const count: usize = @intFromFloat(count_value);
    if (input_length != 4 + count or portfolio < 100 or portfolio > 1_000_000 or
        confidence < 0.5 or confidence > 0.95 or horizon < 1 or horizon > 10) return -1;
    var returns = [_]f64{0} ** 64;
    var sum: f64 = 0;
    for (0..count) |i| {
        const value = values[4 + i];
        if (value < -0.25 or value > 0.25) return -1;
        returns[i] = value;
        sum += value;
    }
    const mean = sum / @as(f64, @floatFromInt(count));
    var squared_deviations: f64 = 0;
    for (0..count) |i| {
        const difference = returns[i] - mean;
        squared_deviations += difference * difference;
    }
    const sample_sd = @sqrt(squared_deviations / @as(f64, @floatFromInt(count - 1)));
    if (sample_sd == 0) return -1;
    const tail_count: usize = @intFromFloat(@floor((1.0 - confidence) * @as(f64, @floatFromInt(count))));
    if (tail_count < 1) return -1;
    for (1..count) |i| {
        const value = returns[i];
        var position = i;
        while (position > 0 and returns[position - 1] > value) : (position -= 1) {
            returns[position] = returns[position - 1];
        }
        returns[position] = value;
    }
    var tail_sum: f64 = 0;
    for (0..tail_count) |i| tail_sum += returns[i];
    const scale = @sqrt(horizon);
    const z = qnorm_r_as241(confidence);
    const es_multiplier = @exp(-0.5 * z * z) / @sqrt(2.0 * PI_VALUE) / (1.0 - confidence);
    var third_moment: f64 = 0;
    var fourth_moment: f64 = 0;
    for (0..count) |i| {
        const difference = returns[i] - mean;
        const square = difference * difference;
        third_moment += square * difference;
        fourth_moment += square * square;
    }
    third_moment /= @as(f64, @floatFromInt(count));
    fourth_moment /= @as(f64, @floatFromInt(count));
    const staged = [_]f64{
        -returns[tail_count - 1] * portfolio * scale,
        -(tail_sum / @as(f64, @floatFromInt(tail_count))) * portfolio * scale,
        portfolio * (z * sample_sd - mean) * scale,
        portfolio * (es_multiplier * sample_sd - mean) * scale,
        mean,
        sample_sd,
        third_moment / (sample_sd * sample_sd * sample_sd),
        fourth_moment / (sample_sd * sample_sd * sample_sd * sample_sd) - 3.0,
    };
    const out = output orelse return -2;
    if (capacity < staged.len) return -2;
    @memcpy(out[0..staged.len], staged[0..]);
    return @intCast(staged.len);
}
