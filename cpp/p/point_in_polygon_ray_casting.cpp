#include <cstddef>
#include <cstdint>

extern "C" std::int64_t point_in_polygon_ray_casting(const std::int64_t *values,
                                                      std::size_t length) {
    if (values == nullptr || length < 9 || length > 131) return -1;
    const std::int64_t n = values[0];
    if (n < 3 || n > 64 || length != static_cast<std::size_t>(3 + 2 * n)) return -1;
    const std::int64_t qx = values[1];
    const std::int64_t qy = values[2];
    constexpr std::int64_t bound = 1'000'000;
    if (qx < -bound || qx > bound || qy < -bound || qy > bound) return -1;
    for (std::int64_t i = 0; i < n; ++i) {
        const std::int64_t x = values[3 + 2 * i];
        const std::int64_t y = values[4 + 2 * i];
        if (x < -bound || x > bound || y < -bound || y > bound) return -1;
    }

    bool inside = false;
    for (std::int64_t i = 0; i < n; ++i) {
        const std::int64_t j = (i + 1) % n;
        const std::int64_t ax = values[3 + 2 * i];
        const std::int64_t ay = values[4 + 2 * i];
        const std::int64_t bx = values[3 + 2 * j];
        const std::int64_t by = values[4 + 2 * j];
        const std::int64_t turn = (bx - ax) * (qy - ay) - (by - ay) * (qx - ax);
        if (turn == 0 && qx >= (ax < bx ? ax : bx) && qx <= (ax > bx ? ax : bx) &&
            qy >= (ay < by ? ay : by) && qy <= (ay > by ? ay : by)) return 1;
        if ((ay > qy) != (by > qy) && ((by > ay && turn > 0) || (by < ay && turn < 0))) inside = !inside;
    }
    return inside ? 1 : 0;
}
