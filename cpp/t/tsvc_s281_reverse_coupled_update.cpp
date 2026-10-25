// Clean-room port of TSVC s281; see the package README for provenance and rights.

#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 16;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value)
{
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 0xffu);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t tsvc_s281_reverse_coupled_update(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t capacity)
{
    if (input == nullptr || length < 5 || length > 50) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_n) ||
        input[1] < 1 || input[1] > 8) return -1;
    const std::size_t n = static_cast<std::size_t>(input[0]);
    const std::size_t passes = static_cast<std::size_t>(input[1]);
    if (length != 2 + 3 * n) return -1;

    double a[max_n], b[max_n], c[max_n];
    for (std::size_t i = 0; i < n; ++i) {
        const std::int64_t av = input[2 + i];
        const std::int64_t bv = input[2 + n + i];
        const std::int64_t cv = input[2 + 2 * n + i];
        if (av < -2 || av > 2 || bv < -2 || bv > 2 || cv < -1 || cv > 1) return -1;
        a[i] = static_cast<double>(av);
        b[i] = static_cast<double>(bv);
        c[i] = static_cast<double>(cv);
    }

    const std::size_t output_bytes = 16 * n;
    if (output == nullptr || capacity < output_bytes) return -2;
    for (std::size_t pass = 0; pass < passes; ++pass) {
        for (std::size_t i = 0; i < n; ++i) {
            const double x = a[n - i - 1] + b[i] * c[i];
            a[i] = x - 1.0;
            b[i] = x;
        }
    }
    for (std::size_t i = 0; i < n; ++i) {
        store_i64_le(output, 8 * i, static_cast<std::int64_t>(a[i]));
        store_i64_le(output, 8 * (n + i), static_cast<std::int64_t>(b[i]));
    }
    return static_cast<std::int64_t>(output_bytes);
}
