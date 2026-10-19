/* Based on Don Cross <dcross@intersrv.com>'s public-domain fft_float
   (intersrv.com/~dcross/fft.html).
   Modified for a bounded float64-slice ABI; the binary32 FFT kernel is retained. */
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
void transform(float real[16], float imag[16], std::size_t n, bool inverse) {
    std::size_t bits = 0;
    for (std::size_t value = n; value > 1; value >>= 1) ++bits;
    for (std::size_t i = 0; i < n; ++i) {
        std::size_t source = i, reverse = 0;
        for (std::size_t b = 0; b < bits; ++b) { reverse = (reverse << 1) | (source & 1u); source >>= 1; }
        if (i < reverse) { float t = real[i]; real[i] = real[reverse]; real[reverse] = t; t = imag[i]; imag[i] = imag[reverse]; imag[reverse] = t; }
    }
    double angle_numerator = inverse ? -2.0 * 3.14159265358979323846 : 2.0 * 3.14159265358979323846;
    std::size_t block_end = 1;
    for (std::size_t block_size = 2; block_size <= n; block_size <<= 1) {
        double delta = angle_numerator / static_cast<double>(block_size);
        double sm2 = std::sin(-2.0 * delta), sm1 = std::sin(-delta);
        double cm2 = std::cos(-2.0 * delta), cm1 = std::cos(-delta), w = 2.0 * cm1;
        for (std::size_t start = 0; start < n; start += block_size) {
            double ar2 = cm2, ar1 = cm1, ai2 = sm2, ai1 = sm1;
            for (std::size_t offset = 0; offset < block_end; ++offset) {
                double ar0 = w * ar1 - ar2; ar2 = ar1; ar1 = ar0;
                double ai0 = w * ai1 - ai2; ai2 = ai1; ai1 = ai0;
                std::size_t first = start + offset, second = first + block_end;
                double tr = ar0 * real[second] - ai0 * imag[second];
                double ti = ar0 * imag[second] + ai0 * real[second];
                real[second] = static_cast<float>(real[first] - tr); imag[second] = static_cast<float>(imag[first] - ti);
                real[first] = static_cast<float>(real[first] + tr); imag[first] = static_cast<float>(imag[first] + ti);
            }
        }
        block_end = block_size;
    }
    if (inverse) for (std::size_t i = 0; i < n; ++i) {
        real[i] = static_cast<float>(static_cast<double>(real[i]) / static_cast<double>(n));
        imag[i] = static_cast<float>(static_cast<double>(imag[i]) / static_cast<double>(n));
    }
}
}

extern "C" std::int64_t mibench_telecomm_fft(const double* input, std::size_t length,
                                               double* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 6 || length > 34) return -1;
    const double nd = input[0], inverse = input[1];
    if (!std::isfinite(nd) || nd != std::trunc(nd) || nd < 2 || nd > 16
        || !std::isfinite(inverse) || inverse != std::trunc(inverse) || (inverse != 0 && inverse != 1)) return -1;
    const auto n = static_cast<std::size_t>(nd);
    if ((n & (n - 1)) != 0 || length != 2 + 2 * n) return -1;
    for (std::size_t i = 2; i < length; ++i) if (!std::isfinite(input[i]) || std::abs(input[i]) > 8.0) return -1;
    const std::size_t required = 2 * n;
    if (output == nullptr || capacity < required) return -2;
    float real[16] = {}, imag[16] = {};
    for (std::size_t i = 0; i < n; ++i) { real[i] = static_cast<float>(input[2 + i]); imag[i] = static_cast<float>(input[2 + n + i]); }
    transform(real, imag, n, inverse != 0);
    double staged[32];
    for (std::size_t i = 0; i < n; ++i) { staged[2 * i] = real[i]; staged[2 * i + 1] = imag[i]; }
    for (std::size_t i = 0; i < required; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(required);
}
