const std = @import("std");
const INVALID_RESULT: f64 = -1.0e300;

fn gamma_recursive_impl(num: f64) f64 {
    if (num == 0.5) return @sqrt(3.14159265358979323846);
    if (num == 1.0) return 1.0;
    return (num - 1.0) * gamma_recursive_impl(num - 1.0);
}

/// Evaluate the source's recursive gamma recurrence on positive half-integers.
export fn gamma_recursive(num: f64) f64 {
    if (!(num >= 0.5 and num <= 20.0) or @mod(num * 2.0, 1.0) != 0.0) return INVALID_RESULT;
    return gamma_recursive_impl(num);
}
