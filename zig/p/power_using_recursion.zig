/// Linear recursive integer power, with a bounded exact contract.
fn powerRecursive(base: i64, exponent: u64) i64 {
    if (exponent == 0) return 1;
    return base * powerRecursive(base, exponent - 1);
}

export fn power_using_recursion(base_encoded: u64, exponent: u64) i64 {
    const base: i64 = @bitCast(base_encoded);
    if (base < -10 or base > 10 or exponent > 15) return std.math.minInt(i64);
    return powerRecursive(base, exponent);
}

const std = @import("std");
