#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_dimension = 64;
constexpr std::size_t max_cells = max_dimension * max_dimension;
constexpr double invalid_result = -1e300;
}

extern "C" double polybench_ludcmp(const std::int64_t *values, std::size_t length) noexcept {
    if (!values || length != 1 || values[0] < 1 || values[0] > max_dimension) return invalid_result;
    const int n = static_cast<int>(values[0]);
    double a[max_cells], product[max_cells], b[max_dimension], x[max_dimension], y[max_dimension];
    for (int i = 0; i < n; ++i) {
        x[i] = 0.0;
        y[i] = 0.0;
        b[i] = (static_cast<double>(i + 1) / static_cast<double>(n)) / 2.0 + 4.0;
    }
    for (int i = 0; i < n; ++i) {
        for (int j = 0; j <= i; ++j)
            a[i * n + j] = static_cast<double>(-static_cast<std::int64_t>(j) % static_cast<std::int64_t>(n)) /
                           static_cast<double>(n) + 1.0;
        for (int j = i + 1; j < n; ++j) a[i * n + j] = 0.0;
        a[i * n + i] = 1.0;
    }
    for (int r = 0; r < n; ++r)
        for (int s = 0; s < n; ++s) product[r * n + s] = 0.0;
    for (int t = 0; t < n; ++t)
        for (int r = 0; r < n; ++r)
            for (int s = 0; s < n; ++s)
                product[r * n + s] = product[r * n + s] + a[r * n + t] * a[s * n + t];
    for (int r = 0; r < n; ++r)
        for (int s = 0; s < n; ++s) a[r * n + s] = product[r * n + s];

    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < i; ++j) {
            double w = a[i * n + j];
            for (int k = 0; k < j; ++k) w = w - a[i * n + k] * a[k * n + j];
            a[i * n + j] = w / a[j * n + j];
        }
        for (int j = i; j < n; ++j) {
            double w = a[i * n + j];
            for (int k = 0; k < i; ++k) w = w - a[i * n + k] * a[k * n + j];
            a[i * n + j] = w;
        }
    }
    for (int i = 0; i < n; ++i) {
        double w = b[i];
        for (int j = 0; j < i; ++j) w = w - a[i * n + j] * y[j];
        y[i] = w;
    }
    for (int i = n - 1; i >= 0; --i) {
        double w = y[i];
        for (int j = i + 1; j < n; ++j) w = w - a[i * n + j] * x[j];
        x[i] = w / a[i * n + i];
    }
    double result = 0.0;
    for (int i = 0; i < n; ++i) result += x[i];
    return result;
}
