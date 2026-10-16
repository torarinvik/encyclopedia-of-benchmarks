#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" double peak_signal_to_noise_ratio(const std::int64_t* v, std::size_t n) noexcept {
    if (!v || n < 3 || n > 129 || v[0] < 1 || v[0] > 64 || n != 1 + 2 * static_cast<std::size_t>(v[0])) return -1e300;
    const auto count = static_cast<std::size_t>(v[0]);
    double sum = 0.0;
    for (std::size_t i = 0; i < count; ++i) {
        const auto a = v[i + 1], b = v[i + 1 + count];
        if (a < 0 || a > 255 || b < 0 || b > 255) return -1e300;
        if (a - b < -15 || a - b > 15) return -1e300;
        const double d = static_cast<double>(a) - static_cast<double>(b); sum += d * d;
    }
    const double mse = sum / static_cast<double>(count);
    if (mse == 0.0) return -1e300;
    return 20.0 * std::log10(255.0 / std::sqrt(mse));
}
