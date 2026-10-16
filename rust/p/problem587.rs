const INVALID_RESULT: f64 = -1.0e300;
const MIN_FRACTION: f64 = 0.001;
const MAX_FRACTION: f64 = 0.1;
const MAX_N: i64 = 100_000;
const PI_VALUE: f64 = 3.141592653589793238462643383279502884;

fn circle_bottom_arc_integral(point: f64) -> f64 {
    ((1.0 - 2.0 * point) * (point - point * point).sqrt() +
        2.0 * point + (1.0 - point).sqrt().asin()) / 4.0
}

fn concave_triangle_area(n: i64) -> f64 {
    let circles = n as f64;
    let intersection_y = (circles + 1.0 - (2.0 * circles).sqrt()) /
                         (2.0 * (circles * circles + 1.0));
    let intersection_x = circles * intersection_y;
    let triangle_area = intersection_x * intersection_y / 2.0;
    let concave_region_area = circle_bottom_arc_integral(0.5) - circle_bottom_arc_integral(intersection_x);
    triangle_area + concave_region_area
}

#[no_mangle]
pub extern "C" fn problem587(fraction: f64) -> f64 {
    if fraction.is_nan() || fraction < MIN_FRACTION || fraction > MAX_FRACTION { return INVALID_RESULT; }
    let l_section_area = (1.0 - PI_VALUE / 4.0) / 4.0;
    for n in 1..=MAX_N {
        if concave_triangle_area(n) / l_section_area < fraction { return n as f64; }
    }
    INVALID_RESULT
}
