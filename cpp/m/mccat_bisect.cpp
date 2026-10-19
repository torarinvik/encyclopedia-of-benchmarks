#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr int max_n = 32;
constexpr std::size_t max_output_bytes = (max_n + 1) * 8;
constexpr double epsilon = 2.2204460492503131e-16;
constexpr std::int64_t invalid_result = -1;
constexpr std::int64_t output_error = -2;

double absolute_value(double value) { return value < 0.0 ? -value : value; }

int sturm(int n, const double* diagonal, const double* off_diagonal,
          const double* beta, double x) {
    int negative_count = 0;
    double q = 1.0;
    for (int i = 0; i < n; ++i) {
        if (q != 0.0) q = (diagonal[i] - x) - beta[i] / q;
        else q = (diagonal[i] - x) - absolute_value(off_diagonal[i]) / epsilon;
        if (q < 0.0) ++negative_count;
    }
    return negative_count;
}

std::size_t store_f64_le(double value, std::uint8_t* output, std::size_t offset) {
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    for (std::size_t i = 0; i < 8; ++i)
        output[offset + i] = static_cast<std::uint8_t>(bits >> (8u * i));
    return offset + 8;
}

std::size_t solve(int n, std::uint8_t* staged) {
    double diagonal[max_n] = {}, off_diagonal[max_n] = {}, beta[max_n] = {};
    double eigenvalues[max_n + 1] = {}, lower_bounds[max_n + 1] = {};
    for (int i = 0; i < n; ++i) {
        const double value = static_cast<double>(i + 1);
        diagonal[i] = value * value;
        diagonal[i] = diagonal[i] * diagonal[i];
        off_diagonal[i] = static_cast<double>(i);
        beta[i] = off_diagonal[i] * off_diagonal[i];
    }
    beta[0] = off_diagonal[0] = 0.0;

    constexpr double fudge = 1.01;
    double xmin = diagonal[n - 1] - fudge * absolute_value(off_diagonal[n - 1]);
    double xmax = diagonal[n - 1] + fudge * absolute_value(off_diagonal[n - 1]);
    for (int i = n - 2; i >= 0; --i) {
        const double h = fudge * (absolute_value(off_diagonal[i]) + absolute_value(off_diagonal[i + 1]));
        if (diagonal[i] + h > xmax) xmax = diagonal[i] + h;
        if (diagonal[i] - h < xmin) xmin = diagonal[i] - h;
    }
    double eps2 = epsilon * (xmin + xmax > 0.0 ? xmax : -xmin);
    double eps1 = epsilon;
    if (eps1 <= 0.0) eps1 = eps2;
    eps2 = 0.5 * eps1 + 7.0 * eps2;

    double x0 = xmax;
    for (int i = n; i >= 1; --i) {
        eigenvalues[i] = xmax;
        lower_bounds[i] = xmin;
    }
    int iterations = 0;
    for (int k = n; k >= 1; --k) {
        double xu = xmin;
        for (int i = k; i >= 1; --i) {
            if (xu < lower_bounds[i]) { xu = lower_bounds[i]; break; }
        }
        if (x0 > eigenvalues[k]) x0 = eigenvalues[k];
        double x1 = (xu + x0) / 2.0;
        while (x0 - xu > 2.0 * epsilon * (absolute_value(xu) + absolute_value(x0)) + eps1) {
            ++iterations;
            const int count = sturm(n, diagonal, off_diagonal, beta, x1);
            if (count < k) {
                if (count < 1) xu = lower_bounds[1] = x1;
                else {
                    xu = lower_bounds[count + 1] = x1;
                    if (eigenvalues[count] > x1) eigenvalues[count] = x1;
                }
            } else x0 = x1;
            x1 = (xu + x0) / 2.0;
        }
        eigenvalues[k] = (xu + x0) / 2.0;
    }

    std::size_t used = 0;
    for (int i = 2; i <= n; ++i) used = store_f64_le(eigenvalues[i], staged, used);
    used = store_f64_le(eps2, staged, used);
    return store_f64_le(static_cast<double>(iterations), staged, used);
}
} // namespace

extern "C" std::int64_t mccat_bisect(const std::int64_t* values, std::size_t length,
                                     std::uint8_t* output, std::size_t output_capacity) {
    if (values == nullptr || length != 1 || values[0] < 2 || values[0] > max_n)
        return invalid_result;
    const std::size_t required = (static_cast<std::size_t>(values[0]) + 1u) * 8u;
    if (output == nullptr || output_capacity < required) return output_error;
    std::uint8_t staged[max_output_bytes];
    const std::size_t used = solve(static_cast<int>(values[0]), staged);
    for (std::size_t i = 0; i < used; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(used);
}
