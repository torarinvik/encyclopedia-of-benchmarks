#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 8;
constexpr std::int64_t kMaxEntry = 1000000000;

void put_f64_le(std::uint8_t *output, std::size_t offset, double value) noexcept {
    const auto bits = [&] { union { double f; std::uint64_t u; } v{value}; return v.u; }();
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t gauss_seidel_method(const std::int64_t *input, std::size_t length,
                                               std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 1 || input[0] < 1 || input[0] > static_cast<std::int64_t>(kMaxN)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != 1 + n * n + n) return -1;
    const auto rhs = 1 + n * n;
    for (std::size_t k = 1; k < length; ++k)
        if (input[k] < -kMaxEntry || input[k] > kMaxEntry) return -1;
    for (std::size_t row = 0; row < n; ++row) {
        const auto diagonal = input[1 + row * n + row];
        if (diagonal <= 0) return -1;
        std::int64_t off_sum = 0;
        for (std::size_t col = 0; col < n; ++col) {
            const auto value = input[1 + row * n + col];
            if (value != input[1 + col * n + row]) return -1;
            if (row != col) off_sum += value < 0 ? -value : value;
        }
        if (diagonal <= off_sum) return -1;
    }
    if (output == nullptr || capacity < n * 8) return -2;

    double a[kMaxN * kMaxN]{}, b[kMaxN]{}, x[kMaxN]{}, old[kMaxN]{};
    for (std::size_t i = 0; i < n * n; ++i) a[i] = static_cast<double>(input[i + 1]) / 1000000.0;
    for (std::size_t i = 0; i < n; ++i) b[i] = static_cast<double>(input[rhs + i]) / 1000000.0;
    for (int iteration = 0; iteration < 1000; ++iteration) {
        for (std::size_t i = 0; i < n; ++i) old[i] = x[i];
        for (std::size_t i = 0; i < n; ++i) {
            double before = 0.0, after = 0.0;
            for (std::size_t j = 0; j < i; ++j) before += a[i * n + j] * x[j];
            for (std::size_t j = i + 1; j < n; ++j) after += a[i * n + j] * old[j];
            x[i] = (b[i] - before - after) / a[i * n + i];
        }
        bool done = true;
        for (std::size_t i = 0; i < n; ++i) if (std::fabs(x[i] - old[i]) >= 1.0e-10) done = false;
        if (done) break;
    }
    for (std::size_t i = 0; i < n; ++i) put_f64_le(output, i * 8, std::round(x[i] * 1.0e10) / 1.0e10);
    return static_cast<std::int64_t>(n * 8);
}
