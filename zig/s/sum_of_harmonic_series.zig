const std = @import("std");
const INVALID_RESULT: f64 = -1.0e300;
export fn sum_of_harmonic_series(first_term: f64, common_difference: f64, number_of_terms: f64) f64 {
    if (!std.math.isFinite(first_term) or !std.math.isFinite(common_difference) or !std.math.isFinite(number_of_terms) or
        first_term <= 0.0 or first_term > 1000.0 or common_difference < 0.0 or common_difference > 1000.0 or
        number_of_terms < 1.0 or number_of_terms > 256.0 or @floor(number_of_terms) != number_of_terms) return INVALID_RESULT;
    const count: i32 = @intFromFloat(number_of_terms);
    var arithmetic_term = 1.0 / first_term;
    var total: f64 = 0.0;
    for (0..@intCast(count)) |index| {
        total += 1.0 / arithmetic_term;
        if (index + 1 < @as(usize, @intCast(count))) arithmetic_term += common_difference;
    }
    return total;
}
