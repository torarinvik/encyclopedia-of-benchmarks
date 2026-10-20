#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
void fft8(double *real, double *imag, bool inverse)
{
    constexpr std::size_t reversed[8] = {0, 4, 2, 6, 1, 5, 3, 7};
    constexpr double pi = 3.14159265358979323846264338327950288;
    for (std::size_t i = 0; i < 8; ++i) {
        const std::size_t j = reversed[i];
        if (i < j) {
            double t = real[i]; real[i] = real[j]; real[j] = t;
            t = imag[i]; imag[i] = imag[j]; imag[j] = t;
        }
    }
    for (std::size_t stage = 1; stage <= 3; ++stage) {
        const std::size_t block = std::size_t{1} << stage, half = block / 2;
        for (std::size_t start = 0; start < 8; start += block) {
            for (std::size_t j = 0; j < half; ++j) {
                const double sign = inverse ? 1.0 : -1.0;
                const double angle = sign * 2.0 * pi * static_cast<double>(j) / static_cast<double>(block);
                const double wr = std::cos(angle), wi = std::sin(angle);
                const std::size_t even = start + j, odd = even + half;
                const double vr = real[odd] * wr - imag[odd] * wi;
                const double vi = real[odd] * wi + imag[odd] * wr;
                const double ur = real[even], ui = imag[even];
                real[even] = ur + vr; imag[even] = ui + vi;
                real[odd] = ur - vr; imag[odd] = ui - vi;
            }
        }
    }
    if (inverse)
        for (std::size_t i = 0; i < 8; ++i) { real[i] /= 8.0; imag[i] /= 8.0; }
}
}

extern "C" std::int64_t rader_fft(const double *input, std::size_t input_length,
                                  double *output, std::size_t output_capacity)
{
    constexpr std::size_t permutation[4] = {1, 2, 4, 3};
    constexpr std::size_t kernel_power[4] = {1, 3, 4, 2};
    constexpr double pi = 3.14159265358979323846264338327950288;
    if (input == nullptr || input_length != 10) return -1;
    for (std::size_t i = 0; i < 10; ++i)
        if (!std::isfinite(input[i]) || input[i] < -100.0 || input[i] > 100.0) return -1;
    if (output == nullptr || output_capacity < 10) return -2;

    double ar[8] = {}, ai[8] = {}, br[8] = {}, bi[8] = {};
    for (std::size_t i = 0; i < 4; ++i) {
        ar[i] = input[2 * permutation[i]]; ai[i] = input[2 * permutation[i] + 1];
        const double angle = -2.0 * pi * static_cast<double>(kernel_power[i]) / 5.0;
        br[i] = std::cos(angle); bi[i] = std::sin(angle);
    }
    fft8(ar, ai, false); fft8(br, bi, false);
    for (std::size_t i = 0; i < 8; ++i) {
        const double real = ar[i] * br[i] - ai[i] * bi[i];
        const double imag = ar[i] * bi[i] + ai[i] * br[i];
        ar[i] = real; ai[i] = imag;
    }
    fft8(ar, ai, true);

    double result[10] = {};
    for (std::size_t n = 0; n < 5; ++n) {
        result[0] += input[2 * n]; result[1] += input[2 * n + 1];
    }
    for (std::size_t k = 1; k < 5; ++k) {
        result[2 * k] = input[0]; result[2 * k + 1] = input[1];
    }
    for (std::size_t i = 0; i < 4; ++i) {
        const std::size_t target = kernel_power[i];
        result[2 * target] += ar[i] + (i + 4 < 8 ? ar[i + 4] : 0.0);
        result[2 * target + 1] += ai[i] + (i + 4 < 8 ? ai[i + 4] : 0.0);
    }
    for (std::size_t i = 0; i < 10; ++i) output[i] = result[i];
    return 10;
}
