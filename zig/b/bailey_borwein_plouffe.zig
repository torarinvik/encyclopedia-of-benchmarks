const std = @import("std");

fn modular_power_16(exponent_value: i64, modulus: i64) i64 {
    var exponent = exponent_value;
    var result: i64 = @rem(1, modulus);
    var base: i64 = @rem(16, modulus);
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = @rem(result * base, modulus);
        base = @rem(base * base, modulus);
        exponent >>= 1;
    }
    return result;
}

fn bbp_subsum(position: i64, addend: i64) f64 {
    var total: f64 = 0.0;
    var index: i64 = 0;
    while (index < position + 1000) : (index += 1) {
        const denominator = 8 * index + addend;
        const exponent = position - 1 - index;
        const term = if (index < position)
            @as(f64, @floatFromInt(modular_power_16(exponent, denominator))) / @as(f64, @floatFromInt(denominator))
        else
            std.math.pow(f64, 16.0, @as(f64, @floatFromInt(exponent))) / @as(f64, @floatFromInt(denominator));
        total += term;
    }
    return total;
}

export fn bailey_borwein_plouffe(position: i64) i64 {
    if (position < 1 or position > 10) return -1;
    const sum_result = 4.0 * bbp_subsum(position, 1) - 2.0 * bbp_subsum(position, 4)
        - bbp_subsum(position, 5) - bbp_subsum(position, 6);
    const fractional = sum_result - @floor(sum_result);
    return @intFromFloat(fractional * 16.0);
}
