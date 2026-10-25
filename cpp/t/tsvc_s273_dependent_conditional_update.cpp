#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 64;
constexpr std::size_t max_passes = 8;
}

extern "C" std::int64_t tsvc_s273_dependent_conditional_update(
    const std::int64_t *values, std::size_t length)
{
    if (values == nullptr || length < 7 || length > 2 + 5 * max_n) return -1;
    const std::int64_t n_value = values[0];
    const std::int64_t passes_value = values[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_n) ||
        passes_value < 1 || passes_value > static_cast<std::int64_t>(max_passes)) return -1;
    const std::size_t n = static_cast<std::size_t>(n_value);
    const std::size_t passes = static_cast<std::size_t>(passes_value);
    if (length != 2 + 5 * n) return -1;
    for (std::size_t index = 2; index < length; ++index) {
        if (values[index] < -2 || values[index] > 2) return -1;
    }

    std::int64_t a[max_n]{}, b[max_n]{}, c[max_n]{}, d[max_n]{}, e[max_n]{};
    for (std::size_t i = 0; i < n; ++i) {
        a[i] = values[2 + i];
        b[i] = values[2 + n + i];
        c[i] = values[2 + 2 * n + i];
        d[i] = values[2 + 3 * n + i];
        e[i] = values[2 + 4 * n + i];
    }
    for (std::size_t pass = 0; pass < passes; ++pass) {
        for (std::size_t i = 0; i < n; ++i) {
            a[i] += d[i] * e[i];
            if (a[i] < 0) b[i] += d[i] * e[i];
            c[i] += a[i] * d[i];
        }
    }
    std::int64_t checksum = 0;
    for (std::size_t i = 0; i < n; ++i) checksum += a[i] + b[i] + c[i];
    return checksum;
}
