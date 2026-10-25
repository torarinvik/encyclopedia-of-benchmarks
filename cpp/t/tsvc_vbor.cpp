#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 128;
}

extern "C" std::int64_t tsvc_vbor(const std::int64_t *values, std::size_t length)
{
    if (values == nullptr || length < 7 || length > 1 + 6 * max_n) return -1;
    const std::int64_t n_value = values[0];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_n)) return -1;
    const std::size_t n = static_cast<std::size_t>(n_value);
    if (length != 1 + 6 * n) return -1;
    for (std::size_t index = 1; index < length; ++index) {
        if (values[index] < 0 || values[index] > 2) return -1;
    }

    std::int64_t checksum = 0;
    for (std::size_t i = 0; i < n; ++i) {
        const std::int64_t a = values[1 + i];
        const std::int64_t b = values[1 + n + i];
        const std::int64_t c = values[1 + 2 * n + i];
        const std::int64_t d = values[1 + 3 * n + i];
        const std::int64_t e = values[1 + 4 * n + i];
        const std::int64_t f = values[1 + 5 * n + i];

        const std::int64_t a1 = a * b * c + a * b * d + a * b * e + a * b * f
            + a * c * d + a * c * e + a * c * f + a * d * e + a * d * f + a * e * f;
        const std::int64_t b1 = b * c * d + b * c * e + b * c * f + b * d * e + b * d * f + b * e * f;
        const std::int64_t c1 = c * d * e + c * d * f + c * e * f;
        const std::int64_t d1 = d * e * f;
        checksum += a1 * b1 * c1 * d1;
    }
    return checksum;
}
