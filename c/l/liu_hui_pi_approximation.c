#include <stdint.h>
#include <stddef.h>
#include <math.h>

int64_t liu_hui_pi_approximation(const int64_t *values, size_t length)
{
    if (values == NULL || length != 1) return -1;
    const int64_t doublings = values[0];
    if (doublings < 0 || doublings > 16) return -1;

    int64_t sides = 6;
    double side = 1.0;
    double apothem = sqrt(0.75);
    for (int64_t i = 0; i < doublings; ++i) {
        const double half_side = side / 2.0;
        const double height = 1.0 - apothem;
        side = sqrt(half_side * half_side + height * height);
        sides *= 2;
        const double next_half_side = side / 2.0;
        apothem = sqrt(1.0 - next_half_side * next_half_side);
    }

    const double area = (double)sides * side * apothem / 2.0;
    return (int64_t)(area * 1000000.0 + 0.5);
}
