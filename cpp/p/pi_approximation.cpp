/* Estimate pi from caller-supplied points in the unit square. */
#include <cstddef>
#include <cstdint>

extern "C" double pi_approximation(const double *points, std::size_t point_count) noexcept
{
    std::uint64_t inside = 0;
    for (std::size_t index = 0; index < point_count; ++index) {
        const double x = points[2 * index];
        const double y = points[2 * index + 1];
        if (x * x + y * y <= 1.0) ++inside;
    }
    return 4.0 * static_cast<double>(inside) / static_cast<double>(point_count);
}
