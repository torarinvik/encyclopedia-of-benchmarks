module problem587;

extern fn double asin(double value);
extern fn double sqrt(double value);
const double INVALID_RESULT = -1.0e300;
const double MIN_FRACTION = 0.001;
const double MAX_FRACTION = 0.1;
const long MAX_N = 100000;
const double PI_VALUE = 3.141592653589793238462643383279502884;

fn double circle_bottom_arc_integral(double point) {
    return ((1.0 - 2.0 * point) * sqrt(point - point * point) +
            2.0 * point + asin(sqrt(1.0 - point))) / 4.0;
}

fn double concave_triangle_area(long n) {
    double circles = n.double();
    double intersection_y = (circles + 1.0 - sqrt(2.0 * circles)) /
                            (2.0 * (circles * circles + 1.0));
    double intersection_x = circles * intersection_y;
    double triangle_area = intersection_x * intersection_y / 2.0;
    double concave_region_area = circle_bottom_arc_integral(0.5) -
                                 circle_bottom_arc_integral(intersection_x);
    return triangle_area + concave_region_area;
}

fn double problem587(double fraction) @export("problem587") {
    if (fraction != fraction || fraction < MIN_FRACTION || fraction > MAX_FRACTION)
        return INVALID_RESULT;
    double l_section_area = (1.0 - PI_VALUE / 4.0) / 4.0;
    for (long n = 1; n <= MAX_N; n++) {
        if (concave_triangle_area(n) / l_section_area < fraction) return n.double();
    }
    return INVALID_RESULT;
}
