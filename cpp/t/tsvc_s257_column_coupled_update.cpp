#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t min_n = 2;
constexpr std::size_t max_n = 8;
constexpr std::size_t max_passes = 4;
}

extern "C" std::int64_t tsvc_s257_column_coupled_update(
    const std::int64_t *values, std::size_t length)
{
    if (values == nullptr || length < 12 || length > 2 + max_n + 2 * max_n * max_n) return -1;
    const std::int64_t n_value = values[0];
    const std::int64_t passes_value = values[1];
    if (n_value < static_cast<std::int64_t>(min_n) || n_value > static_cast<std::int64_t>(max_n) ||
        passes_value < 1 || passes_value > static_cast<std::int64_t>(max_passes)) return -1;
    const std::size_t n = static_cast<std::size_t>(n_value);
    const std::size_t passes = static_cast<std::size_t>(passes_value);
    if (length != 2 + n + 2 * n * n) return -1;
    for (std::size_t index = 2; index < length; ++index) {
        if (values[index] < -1 || values[index] > 1) return -1;
    }

    std::int64_t a[max_n]{};
    std::int64_t aa[max_n * max_n]{};
    std::int64_t bb[max_n * max_n]{};
    for (std::size_t i = 0; i < n; ++i) a[i] = values[2 + i];
    const std::size_t aa_start = 2 + n;
    const std::size_t bb_start = aa_start + n * n;
    for (std::size_t i = 0; i < n * n; ++i) {
        aa[i] = values[aa_start + i];
        bb[i] = values[bb_start + i];
    }

    for (std::size_t pass = 0; pass < passes; ++pass) {
        for (std::size_t i = 1; i < n; ++i) {
            for (std::size_t j = 0; j < n; ++j) {
                const std::size_t cell = j * n + i;
                a[i] = aa[cell] - a[i - 1];
                aa[cell] = a[i] + bb[cell];
            }
        }
    }

    std::int64_t checksum = 0;
    for (std::size_t i = 0; i < n; ++i) checksum += a[i];
    for (std::size_t i = 0; i < n * n; ++i) checksum += aa[i];
    return checksum;
}
