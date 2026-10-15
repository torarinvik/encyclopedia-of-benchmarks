const std = @import("std");

const INVALID_RESULT: f64 = -1.0e300;

export fn equated_monthly_installments(principal: f64, rate_per_annum: f64, years_to_repay: f64) f64 {
    if (std.math.isNan(principal) or std.math.isNan(rate_per_annum) or std.math.isNan(years_to_repay) or
        principal <= 0.0 or principal > 1_000_000.0 or rate_per_annum < 0.0001 or rate_per_annum > 0.2 or
        years_to_repay < 1.0 or years_to_repay > 30.0 or @floor(years_to_repay) != years_to_repay) return INVALID_RESULT;
    const monthly_rate = rate_per_annum / 12.0;
    const payments = years_to_repay * 12.0;
    const factor = std.math.pow(f64, 1.0 + monthly_rate, payments);
    return principal * monthly_rate * factor / (factor - 1.0);
}
