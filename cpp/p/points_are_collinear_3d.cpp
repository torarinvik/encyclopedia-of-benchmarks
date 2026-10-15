/* Check whether three bounded integer points lie on one 3D line. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t points_are_collinear_3d(const std::int64_t *values, std::size_t length) noexcept
{
    if (values == nullptr || length != 9) return -1;
    for (std::size_t index = 0; index < 9; ++index) {
        if (values[index] < -10000 || values[index] > 10000) return -1;
    }

    const std::int64_t abx = values[3] - values[0];
    const std::int64_t aby = values[4] - values[1];
    const std::int64_t abz = values[5] - values[2];
    const std::int64_t acx = values[6] - values[0];
    const std::int64_t acy = values[7] - values[1];
    const std::int64_t acz = values[8] - values[2];
    const std::int64_t cross_x = aby * acz - abz * acy;
    const std::int64_t cross_y = abz * acx - abx * acz;
    const std::int64_t cross_z = abx * acy - aby * acx;
    return cross_x == 0 && cross_y == 0 && cross_z == 0 ? 1 : 0;
}
