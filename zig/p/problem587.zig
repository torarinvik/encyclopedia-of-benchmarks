const std = @import("std");
const INVALID_RESULT: f64 = -1.0e300;
const MIN_FRACTION: f64 = 0.001;
const MAX_FRACTION: f64 = 0.1;
const MAX_N: i64 = 100_000;
const PI_VALUE: f64 = 3.141592653589793238462643383279502884;

fn circleBottomArcIntegral(point: f64) f64 {
    return ((1.0 - 2.0 * point) * @sqrt(point - point * point) +
        2.0 * point + @asin(@sqrt(1.0 - point))) / 4.0;
}

fn concaveTriangleArea(n: i64) f64 {
    const circles: f64 = @floatFromInt(n);
    const intersection_y = (circles + 1.0 - @sqrt(2.0 * circles)) /
        (2.0 * (circles * circles + 1.0));
    const intersection_x = circles * intersection_y;
    const triangle_area = intersection_x * intersection_y / 2.0;
    const concave_region_area = circleBottomArcIntegral(0.5) - circleBottomArcIntegral(intersection_x);
    return triangle_area + concave_region_area;
}

pub export fn problem587(fraction: f64) f64 {
    if (std.math.isNan(fraction) or fraction < MIN_FRACTION or fraction > MAX_FRACTION)
        return INVALID_RESULT;
    const l_section_area = (1.0 - PI_VALUE / 4.0) / 4.0;
    var n: i64 = 1;
    while (n <= MAX_N) : (n += 1) {
        if (concaveTriangleArea(n) / l_section_area < fraction) return @floatFromInt(n);
    }
    return INVALID_RESULT;
}
