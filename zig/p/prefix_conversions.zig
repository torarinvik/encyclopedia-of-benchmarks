const std = @import("std");

fn siExponent(code: f64) i32 {
    if (code == 0.0) return 24;
    if (code == 1.0) return 21;
    if (code == 2.0) return 18;
    if (code == 3.0) return 15;
    if (code == 4.0) return 12;
    if (code == 5.0) return 9;
    if (code == 6.0) return 6;
    if (code == 7.0) return 3;
    if (code == 8.0) return 2;
    if (code == 9.0) return 1;
    if (code == 10.0) return -1;
    if (code == 11.0) return -2;
    if (code == 12.0) return -3;
    if (code == 13.0) return -6;
    if (code == 14.0) return -9;
    if (code == 15.0) return -12;
    if (code == 16.0) return -15;
    if (code == 17.0) return -18;
    if (code == 18.0) return -21;
    if (code == 19.0) return -24;
    return 1000;
}

fn binaryExponent(code: f64) i32 {
    if (code == 20.0) return 8;
    if (code == 21.0) return 7;
    if (code == 22.0) return 6;
    if (code == 23.0) return 5;
    if (code == 24.0) return 4;
    if (code == 25.0) return 3;
    if (code == 26.0) return 2;
    if (code == 27.0) return 1;
    return 1000;
}

/// Convert amount between SI or binary prefixes using the source formulas.
export fn prefix_conversions(known_amount: f64, known_code: f64, unknown_code: f64) f64 {
    if (std.math.isNan(known_amount) or known_amount < -1_000_000.0 or known_amount > 1_000_000.0) return -1e300;
    const known_si = siExponent(known_code);
    const unknown_si = siExponent(unknown_code);
    if (known_si != 1000 and unknown_si != 1000)
        return known_amount * std.math.pow(f64, 10.0, @as(f64, @floatFromInt(known_si - unknown_si)));
    const known_binary = binaryExponent(known_code);
    const unknown_binary = binaryExponent(unknown_code);
    if (known_binary != 1000 and unknown_binary != 1000)
        return known_amount * std.math.pow(f64, 2.0, @as(f64, @floatFromInt((known_binary - unknown_binary) * 10)));
    return -1e300;
}
