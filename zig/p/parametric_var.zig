const std = @import("std");

const MAX_PARSEABLE_INPUT_LENGTH: usize = 69;

fn qnorm(confidence: f64) f64 {
    const q = confidence - 0.5;
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
        return q * (numerator / denominator);
    }

    // The supported confidence range only uses the moderate upper tail.
    const r = @sqrt(-@log(1.0 - confidence)) - 1.6;
    var numerator: f64 = 7.7454501427834140764e-4;
    numerator = numerator * r + 0.0227238449892691845833;
    numerator = numerator * r + 0.24178072517745061177;
    numerator = numerator * r + 1.27045825245236838258;
    numerator = numerator * r + 3.64784832476320460504;
    numerator = numerator * r + 5.7694972214606914055;
    numerator = numerator * r + 4.6303378461565452959;
    numerator = numerator * r + 1.42343711074968357734;

    var denominator: f64 = 1.05075007164441684324e-9;
    denominator = denominator * r + 5.475938084995344946e-4;
    denominator = denominator * r + 0.0151986665636164571966;
    denominator = denominator * r + 0.14810397642748007459;
    denominator = denominator * r + 0.68976733498510000455;
    denominator = denominator * r + 1.6763848301838038494;
    denominator = denominator * r + 2.05319162663775882187;
    denominator = denominator * r + 1.0;
    return numerator / denominator;
}

export fn calculate_var_parametric(input_opt: ?[*]const f64, input_length: usize,
    output_opt: ?[*]f64, output_capacity: usize) i64 {
    const values = input_opt orelse return -1;
    if (input_length < 24 or input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    for (0..input_length) |index| {
        if (!std.math.isFinite(values[index])) return -1;
    }

    const portfolio_value = values[0];
    const confidence_level = values[1];
    const time_horizon = values[2];
    const count_value = values[3];
    if (@trunc(count_value) != count_value or count_value < 20.0 or count_value > 64.0) return -1;
    const return_count: usize = @intFromFloat(count_value);
    if (input_length != 4 + return_count or
        portfolio_value < 100.0 or portfolio_value > 1_000_000.0 or
        confidence_level < 0.5 or confidence_level > 0.95 or
        time_horizon < 1.0 or time_horizon > 10.0) return -1;

    var mean: f64 = 0.0;
    for (0..return_count) |index| {
        const value = values[4 + index];
        if (value < -0.25 or value > 0.25) return -1;
        mean += value;
    }
    mean /= @as(f64, @floatFromInt(return_count));
    var squared_deviations: f64 = 0.0;
    for (0..return_count) |index| {
        const difference = values[4 + index] - mean;
        squared_deviations += difference * difference;
    }
    const sample_sd = @sqrt(squared_deviations / @as(f64, @floatFromInt(return_count - 1)));
    const result = portfolio_value * (qnorm(confidence_level) * sample_sd - mean) * @sqrt(time_horizon);

    const output = output_opt orelse return -2;
    if (output_capacity < 1) return -2;
    output[0] = result;
    return 1;
}
