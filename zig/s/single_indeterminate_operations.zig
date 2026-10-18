const std = @import("std");

const MAX_PARSEABLE_INPUT_LENGTH: usize = 22;
const MAX_DEGREE: usize = 8;
const MAX_OUTPUT_ELEMENTS: usize = 17;

fn exactInteger(value: f64, minimum: f64, maximum: f64) bool {
    return std.math.isFinite(value) and @trunc(value) == value and value >= minimum and value <= maximum;
}

export fn single_indeterminate_operations(input: ?[*]const f64, input_length: usize,
    output: ?[*]f64, capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 3 or input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    for (values[0..input_length]) |value| {
        if (!std.math.isFinite(value)) return -1;
    }
    if (!exactInteger(values[0], 0, 5)) return -1;
    const operation: usize = @intFromFloat(values[0]);
    var cursor: usize = 1;
    if (!exactInteger(values[cursor], 0, MAX_DEGREE)) return -1;
    const degree_a: usize = @intFromFloat(values[cursor]);
    cursor += 1;
    var coefficients_a = [_]f64{0} ** (MAX_DEGREE + 1);
    if (cursor + degree_a + 1 > input_length) return -1;
    for (0..degree_a + 1) |index| {
        const value = values[cursor + index];
        if (value < -10 or value > 10) return -1;
        coefficients_a[index] = value;
    }
    cursor += degree_a + 1;

    var degree_b: usize = 0;
    var coefficients_b = [_]f64{0} ** (MAX_DEGREE + 1);
    var parameter: f64 = 0;
    if (operation <= 2) {
        if (cursor >= input_length or !exactInteger(values[cursor], 0, MAX_DEGREE)) return -1;
        degree_b = @intFromFloat(values[cursor]);
        cursor += 1;
        if (cursor + degree_b + 1 > input_length) return -1;
        for (0..degree_b + 1) |index| {
            const value = values[cursor + index];
            if (value < -10 or value > 10) return -1;
            coefficients_b[index] = value;
        }
        cursor += degree_b + 1;
        if (cursor != input_length) return -1;
    } else if (operation == 3 or operation == 5) {
        if (cursor + 1 != input_length) return -1;
        parameter = values[cursor];
        if (operation == 3) {
            if (parameter < -2 or parameter > 2) return -1;
        } else if (parameter < -10 or parameter > 10) return -1;
        cursor += 1;
    } else if (cursor != input_length) return -1;

    var staged = [_]f64{0} ** MAX_OUTPUT_ELEMENTS;
    var result_length: usize = 0;
    switch (operation) {
        0 => {
            result_length = @max(degree_a, degree_b) + 1;
            if (degree_a > degree_b) {
                @memcpy(staged[0 .. degree_a + 1], coefficients_a[0 .. degree_a + 1]);
                for (0..degree_b + 1) |index| staged[index] += coefficients_b[index];
            } else {
                @memcpy(staged[0 .. degree_b + 1], coefficients_b[0 .. degree_b + 1]);
                for (0..degree_a + 1) |index| staged[index] += coefficients_a[index];
            }
        },
        1 => {
            var negated_b = [_]f64{0} ** (MAX_DEGREE + 1);
            for (0..degree_b + 1) |index| negated_b[index] = coefficients_b[index] * -1.0;
            result_length = @max(degree_a, degree_b) + 1;
            if (degree_a > degree_b) {
                @memcpy(staged[0 .. degree_a + 1], coefficients_a[0 .. degree_a + 1]);
                for (0..degree_b + 1) |index| staged[index] += negated_b[index];
            } else {
                @memcpy(staged[0 .. degree_b + 1], negated_b[0 .. degree_b + 1]);
                for (0..degree_a + 1) |index| staged[index] += coefficients_a[index];
            }
        },
        2 => {
            result_length = degree_a + degree_b + 1;
            for (0..degree_a + 1) |left| {
                for (0..degree_b + 1) |right| {
                    staged[left + right] += coefficients_a[left] * coefficients_b[right];
                }
            }
        },
        3 => {
            result_length = 1;
            for (0..degree_a + 1) |index| {
                const exponent: f64 = @floatFromInt(index);
                staged[0] += coefficients_a[index] * std.math.pow(f64, parameter, exponent);
            }
        },
        4 => {
            result_length = degree_a;
            for (0..degree_a) |index| staged[index] = coefficients_a[index + 1] * @as(f64, @floatFromInt(index + 1));
        },
        5 => {
            result_length = degree_a + 2;
            staged[0] = parameter;
            for (0..degree_a + 1) |index| staged[index + 1] = coefficients_a[index] / @as(f64, @floatFromInt(index + 1));
        },
        else => unreachable,
    }
    for (staged[0..result_length]) |value| {
        if (!std.math.isFinite(value)) return -1;
    }
    const out = output orelse return -2;
    if (capacity < result_length) return -2;
    @memcpy(out[0..result_length], staged[0..result_length]);
    return @intCast(result_length);
}
