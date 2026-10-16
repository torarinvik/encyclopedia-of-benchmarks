const MAX_MILLI_VALUE: i64 = 100_000;
const MAX_SUCCESS_COUNT: i64 = 20;
const INVALID_RESULT: f64 = -1.0e300;

fn poissonFactorial(x: f64) f64 {
    var factorial = x;
    var index: i64 = @as(i64, @intFromFloat(x)) - 1;
    while (index > 0) : (index -= 1) factorial *= @as(f64, @floatFromInt(index));
    if (factorial <= 0.0) factorial = 1.0;
    return factorial;
}

fn poissonPoint(mean: f64, successes: i64) f64 {
    return (std.math.pow(f64, mean, @as(f64, @floatFromInt(successes))) * @exp(-mean)) /
        poissonFactorial(@as(f64, @floatFromInt(successes)));
}

const std = @import("std");

export fn poisson_dist(input: [*c]const i64, length: usize) f64 {
    if (input == null or length != 4) return INVALID_RESULT;
    const operation = input[0];
    const first = input[1];
    const second = input[2];
    const third = input[3];
    if (operation == 0) {
        if (first < 0 or first > MAX_MILLI_VALUE or second < 1 or second > MAX_MILLI_VALUE or third != 0)
            return INVALID_RESULT;
        return (@as(f64, @floatFromInt(first)) / 1000.0) /
            (@as(f64, @floatFromInt(second)) / 1000.0);
    }
    if (operation == 1) {
        if (first < 0 or first > MAX_MILLI_VALUE or second < 0 or second > MAX_MILLI_VALUE or third != 0)
            return INVALID_RESULT;
        return (@as(f64, @floatFromInt(first)) / 1000.0) *
            (@as(f64, @floatFromInt(second)) / 1000.0);
    }
    if (operation == 2) {
        if (first < 0 or first > MAX_MILLI_VALUE or second < 0 or second > MAX_SUCCESS_COUNT or third != 0)
            return INVALID_RESULT;
        return poissonPoint(@as(f64, @floatFromInt(first)) / 1000.0, second);
    }
    if (operation == 3) {
        if (first < 0 or first > MAX_MILLI_VALUE or second < 0 or second > third or third > MAX_SUCCESS_COUNT)
            return INVALID_RESULT;
        const mean = @as(f64, @floatFromInt(first)) / 1000.0;
        var probability: f64 = 0.0;
        var successes = second;
        while (successes <= third) : (successes += 1)
            probability += poissonPoint(mean, successes);
        return probability;
    }
    return INVALID_RESULT;
}
