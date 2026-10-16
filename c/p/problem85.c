/* Search triangular-number products for the rectangle count nearest the target. */
#include <math.h>
#include <stdint.h>

#define MAX_TARGET INT64_C(2000000000)

static int64_t triangle(int64_t side)
{
    return side * (side + 1) / 2;
}

static int64_t absolute_difference(int64_t left, int64_t right)
{
    const int64_t difference = left - right;
    return difference < 0 ? -difference : difference;
}

int64_t problem85(int64_t target)
{
    if (target < 0 || target > MAX_TARGET) return -1;
    const int64_t bound = (int64_t)ceil(sqrt((double)(target * 2)) * 1.1);
    int64_t best_product = 0;
    int64_t area = 0;
    int64_t triangle_a = 0;
    for (int64_t a = 1; a < bound; ++a) {
        triangle_a += a;
        const double estimate =
            (-1.0 + sqrt(1.0 + 8.0 * (double)target / (double)triangle_a)) / 2.0;
        const int64_t b_floor = (int64_t)floor(estimate);
        const int64_t b_ceil = (int64_t)ceil(estimate);
        const int64_t first_product = triangle_a * triangle(b_floor);
        const int64_t second_product = triangle_a * triangle(b_ceil);
        if (absolute_difference(target, first_product) <
            absolute_difference(target, best_product)) {
            best_product = first_product;
            area = a * b_floor;
        }
        if (absolute_difference(target, second_product) <
            absolute_difference(target, best_product)) {
            best_product = second_product;
            area = a * b_ceil;
        }
    }
    return area;
}
