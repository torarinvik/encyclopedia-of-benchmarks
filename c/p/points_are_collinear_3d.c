/* Check whether three bounded integer points lie on one 3D line. */
#include <stddef.h>
#include <stdint.h>

int64_t points_are_collinear_3d(const int64_t *values, size_t length)
{
    if (values == NULL || length != 9) return -1;
    for (size_t index = 0; index < 9; ++index) {
        if (values[index] < -10000 || values[index] > 10000) return -1;
    }

    const int64_t abx = values[3] - values[0];
    const int64_t aby = values[4] - values[1];
    const int64_t abz = values[5] - values[2];
    const int64_t acx = values[6] - values[0];
    const int64_t acy = values[7] - values[1];
    const int64_t acz = values[8] - values[2];
    const int64_t cross_x = aby * acz - abz * acy;
    const int64_t cross_y = abz * acx - abx * acz;
    const int64_t cross_z = abx * acy - aby * acx;
    return cross_x == 0 && cross_y == 0 && cross_z == 0 ? 1 : 0;
}
