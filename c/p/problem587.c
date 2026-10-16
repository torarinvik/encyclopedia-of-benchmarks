#include <math.h>

#define INVALID_RESULT (-1.0e300)
#define MIN_FRACTION 0.001
#define MAX_FRACTION 0.1
#define MAX_N 100000
#define PI_VALUE 3.141592653589793238462643383279502884

static double circle_bottom_arc_integral(double point)
{
    return ((1.0 - 2.0 * point) * sqrt(point - point * point) +
            2.0 * point + asin(sqrt(1.0 - point))) / 4.0;
}

static double concave_triangle_area(int n)
{
    const double circles = (double)n;
    const double intersection_y = (circles + 1.0 - sqrt(2.0 * circles)) /
                                  (2.0 * (circles * circles + 1.0));
    const double intersection_x = circles * intersection_y;
    const double triangle_area = intersection_x * intersection_y / 2.0;
    const double concave_region_area = circle_bottom_arc_integral(0.5) -
                                       circle_bottom_arc_integral(intersection_x);
    return triangle_area + concave_region_area;
}

double problem587(double fraction)
{
    if (fraction != fraction || fraction < MIN_FRACTION || fraction > MAX_FRACTION)
        return INVALID_RESULT;
    const double l_section_area = (1.0 - PI_VALUE / 4.0) / 4.0;
    for (int n = 1; n <= MAX_N; ++n) {
        if (concave_triangle_area(n) / l_section_area < fraction) return (double)n;
    }
    return INVALID_RESULT;
}
