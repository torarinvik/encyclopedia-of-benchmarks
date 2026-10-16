const std = @import("std");

const INVALID_RESULT: f64 = -1.0e300;

export fn sigmoid_without_inbuilt(x: f64, slope: f64) f64 {
    if (!std.math.isFinite(x) or !std.math.isFinite(slope) or x < -10.0 or x > 10.0
        or slope < -10.0 or slope > 10.0) return INVALID_RESULT;
    return 1.0 / (1.0 + @exp(-slope * x));
}

