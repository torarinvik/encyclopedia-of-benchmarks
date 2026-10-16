#include <complex>
#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <cmath>

extern "C" double durand_kerner_roots(const int64_t *v, std::size_t n) {
    if (!v || n != 3 || v[0] == 0 || v[0] < -4 || v[0] > 4 ||
        v[1] < 0 || v[1] > 2 || v[2] < 0 || v[2] > 1) return -1.0e300;
    const double d = static_cast<double>(v[0]), s = d > 0 ? 1.0 : -1.0;
    const double q = std::sqrt(3.0) / 2.0;
    std::complex<double> z[3] = {s, s * std::complex<double>(-0.5, q), s * std::complex<double>(-0.5, -q)};
    for (int it = 0; it < 100; ++it) {
        std::complex<double> next[3];
        double change = 0.0;
        for (int i = 0; i < 3; ++i) {
            std::complex<double> den = 1.0;
            for (int j = 0; j < 3; ++j) if (i != j) den *= z[i] - z[j];
            next[i] = z[i] - (z[i] * z[i] * z[i] - d) / den;
            change = std::max(change, std::abs(next[i] - z[i]));
        }
        for (int i = 0; i < 3; ++i) z[i] = next[i];
        if (change < 1.0e-14) break;
    }
    const auto &root = z[v[1]];
    return v[2] == 0 ? root.real() : root.imag();
}
