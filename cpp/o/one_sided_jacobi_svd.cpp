#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t one_sided_jacobi_svd(const std::int64_t* input, std::size_t length) noexcept {
    constexpr int nmax = 6;
    if (input == nullptr || length < 3 || length > 39) return -1;
    const std::int64_t m64 = input[0], n64 = input[1];
    if (n64 < 1 || n64 > nmax || m64 < n64 || m64 > nmax || length != 2 + static_cast<std::size_t>(m64 * n64)) return -1;
    const int m = static_cast<int>(m64), n = static_cast<int>(n64);
    double a[nmax][nmax]{};
    for (int r = 0; r < m; ++r) for (int col = 0; col < n; ++col) {
        const std::int64_t x = input[2 + r * n + col];
        if (x < -8 || x > 8) return -1;
        a[r][col] = static_cast<double>(x);
    }
    bool converged = false;
    for (int sweep = 0; sweep < 128; ++sweep) {
        bool changed = false;
        for (int p = 0; p < n; ++p) for (int q = p + 1; q < n; ++q) {
            double alpha = 0.0, beta = 0.0, gamma = 0.0;
            for (int r = 0; r < m; ++r) { const double x=a[r][p], y=a[r][q]; alpha+=x*x; beta+=y*y; gamma+=x*y; }
            if (alpha == 0.0 || beta == 0.0 || std::abs(gamma) <= 1.0e-14 * std::sqrt(alpha * beta)) continue;
            const double tau = (beta - alpha) / (2.0 * gamma);
            const double t = tau == 0.0 ? 1.0 : (tau > 0.0 ? 1.0 : -1.0) / (std::abs(tau) + std::sqrt(1.0 + tau*tau));
            const double c = 1.0 / std::sqrt(1.0 + t*t), s = c*t;
            for (int r = 0; r < m; ++r) { const double x=a[r][p], y=a[r][q]; a[r][p]=c*x-s*y; a[r][q]=s*x+c*y; }
            changed = true;
        }
        if (!changed) { converged = true; break; }
    }
    if (!converged) return -1;
    double sigma[nmax]{};
    for (int col = 0; col < n; ++col) { for (int r = 0; r < m; ++r) sigma[col] += a[r][col] * a[r][col]; sigma[col] = std::sqrt(sigma[col]); }
    for (int i = 0; i < n; ++i) for (int j = i+1; j < n; ++j) if (sigma[j] > sigma[i]) { const double t=sigma[i]; sigma[i]=sigma[j]; sigma[j]=t; }
    double signature = 0.0;
    for (int i = 0; i < n; ++i) signature += static_cast<double>(i+1) * sigma[i];
    return static_cast<std::int64_t>(signature * 1000.0 + 0.5);
}
