#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxSide = 4;
constexpr std::size_t kMaxPoints = kMaxSide * kMaxSide * kMaxSide;
constexpr std::size_t kMaxSteps = 6;
constexpr std::size_t kMaxInputLength = 2 + 2 * kMaxPoints;
constexpr std::size_t kChecksumTerms = 64;
constexpr double kTau = 6.28318530717958647692528676655900577;
constexpr double kAlpha = 1.0e-6;

bool bounded_integer(double value, double minimum, double maximum) {
    return std::isfinite(value) && std::trunc(value) == value
        && value >= minimum && value <= maximum;
}

void fft_line(double* real, double* imag, std::size_t n, bool inverse) {
    std::size_t reverse = 0;
    for (std::size_t position = 1; position < n; ++position) {
        std::size_t bit = n >> 1;
        for (; bit != 0 && (reverse & bit) != 0; bit >>= 1) reverse ^= bit;
        reverse ^= bit;
        if (position < reverse) {
            double temporary = real[position]; real[position] = real[reverse]; real[reverse] = temporary;
            temporary = imag[position]; imag[position] = imag[reverse]; imag[reverse] = temporary;
        }
    }
    for (std::size_t block = 2; block <= n; block <<= 1) {
        const double angle = (inverse ? 1.0 : -1.0) * kTau / static_cast<double>(block);
        const double step_real = std::cos(angle), step_imag = std::sin(angle);
        for (std::size_t start = 0; start < n; start += block) {
            double weight_real = 1.0, weight_imag = 0.0;
            for (std::size_t offset = 0; offset < block / 2; ++offset) {
                const std::size_t first = start + offset, second = first + block / 2;
                const double product_real = weight_real * real[second] - weight_imag * imag[second];
                const double product_imag = weight_real * imag[second] + weight_imag * real[second];
                const double first_real = real[first], first_imag = imag[first];
                real[first] = first_real + product_real; imag[first] = first_imag + product_imag;
                real[second] = first_real - product_real; imag[second] = first_imag - product_imag;
                const double next_real = weight_real * step_real - weight_imag * step_imag;
                weight_imag = weight_real * step_imag + weight_imag * step_real;
                weight_real = next_real;
            }
        }
    }
    if (inverse) for (std::size_t i = 0; i < n; ++i) {
        real[i] /= static_cast<double>(n); imag[i] /= static_cast<double>(n);
    }
}

void axis_transform(double* real, double* imag, std::size_t n,
                    std::size_t axis, bool inverse) {
    double line_real[kMaxSide], line_imag[kMaxSide];
    for (std::size_t a = 0; a < n; ++a) for (std::size_t b = 0; b < n; ++b) {
        for (std::size_t p = 0; p < n; ++p) {
            std::size_t x = a, y = b, z = p;
            if (axis == 0) { x = p; y = a; z = b; }
            else if (axis == 1) { x = a; y = p; z = b; }
            const std::size_t index = (x * n + y) * n + z;
            line_real[p] = real[index]; line_imag[p] = imag[index];
        }
        fft_line(line_real, line_imag, n, inverse);
        for (std::size_t p = 0; p < n; ++p) {
            std::size_t x = a, y = b, z = p;
            if (axis == 0) { x = p; y = a; z = b; }
            else if (axis == 1) { x = a; y = p; z = b; }
            const std::size_t index = (x * n + y) * n + z;
            real[index] = line_real[p]; imag[index] = line_imag[p];
        }
    }
}

void transform3d(double* real, double* imag, std::size_t n, bool inverse) {
    axis_transform(real, imag, n, 2, inverse);
    axis_transform(real, imag, n, 1, inverse);
    axis_transform(real, imag, n, 0, inverse);
}

int signed_frequency(std::size_t index, std::size_t n) {
    return index <= n / 2 ? static_cast<int>(index) : static_cast<int>(index) - static_cast<int>(n);
}
}  // namespace

extern "C" std::int64_t npb_ft_3d_spectral_step(const double* input,
    std::size_t length, double* output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > kMaxInputLength) return -1;
    if (!bounded_integer(input[0], 2.0, static_cast<double>(kMaxSide))
        || !bounded_integer(input[1], 1.0, static_cast<double>(kMaxSteps))) return -1;
    const std::size_t n = static_cast<std::size_t>(input[0]);
    const std::size_t steps = static_cast<std::size_t>(input[1]);
    if ((n != 2 && n != 4) || length != 2 + 2 * n * n * n) return -1;
    const std::size_t volume = n * n * n, needed = 2 * steps;
    for (std::size_t i = 2; i < length; ++i)
        if (!std::isfinite(input[i]) || input[i] < -1.0 || input[i] > 1.0) return -1;
    if (output == nullptr || capacity < needed) return -2;

    double spectrum_real[kMaxPoints]{}, spectrum_imag[kMaxPoints]{};
    double work_real[kMaxPoints]{}, work_imag[kMaxPoints]{};
    for (std::size_t i = 0; i < volume; ++i) {
        spectrum_real[i] = input[2 + 2 * i]; spectrum_imag[i] = input[2 + 2 * i + 1];
    }
    transform3d(spectrum_real, spectrum_imag, n, false);
    for (std::size_t step = 1; step <= steps; ++step) {
        for (std::size_t x = 0; x < n; ++x) for (std::size_t y = 0; y < n; ++y) for (std::size_t z = 0; z < n; ++z) {
            const std::size_t index = (x * n + y) * n + z;
            const int kx = signed_frequency(x, n), ky = signed_frequency(y, n), kz = signed_frequency(z, n);
            const double radius_squared = static_cast<double>(kx * kx + ky * ky + kz * kz);
            const double factor = std::exp(-4.0 * 3.14159265358979323846264338327950288
                * 3.14159265358979323846264338327950288 * kAlpha * static_cast<double>(step) * radius_squared);
            work_real[index] = spectrum_real[index] * factor;
            work_imag[index] = spectrum_imag[index] * factor;
        }
        transform3d(work_real, work_imag, n, true);
        double sum_real = 0.0, sum_imag = 0.0;
        for (std::size_t j = 1; j <= kChecksumTerms; ++j) {
            const std::size_t x = (j - 1) % n, y = (3 * j - 1) % n, z = (5 * j - 1) % n;
            const std::size_t index = (x * n + y) * n + z;
            sum_real += work_real[index]; sum_imag += work_imag[index];
        }
        output[2 * (step - 1)] = sum_real / static_cast<double>(volume);
        output[2 * (step - 1) + 1] = sum_imag / static_cast<double>(volume);
    }
    return static_cast<std::int64_t>(needed);
}
