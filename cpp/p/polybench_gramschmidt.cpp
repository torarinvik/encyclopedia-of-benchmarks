/* Clean-room bounded PolyBench QR port. See package LICENSE.txt. */
#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t polybench_gramschmidt(const double *input,
        std::size_t length, double *output, std::size_t capacity) noexcept {
    if (!input || length != 2 || !std::isfinite(input[0]) || !std::isfinite(input[1]) ||
        std::trunc(input[0]) != input[0] || std::trunc(input[1]) != input[1] ||
        input[0] < 1.0 || input[0] > 6.0 || input[1] < 1.0 || input[1] > 6.0 || input[1] > input[0]) return -1;
    const auto m = static_cast<std::size_t>(input[0]), n = static_cast<std::size_t>(input[1]);
    const auto q_cells = m*n, r_cells = n*n, total = q_cells+r_cells;
    if (!output || capacity < total) return -2;
    double a[36]{}, q[36]{}, r[36]{}, staged[72]{};
    for (std::size_t i=0;i<m;++i) for (std::size_t j=0;j<n;++j)
        a[i*n+j] = (static_cast<double>((i*j)%m) / static_cast<double>(m)) * 100.0 + 10.0;
    for (std::size_t k=0;k<n;++k) {
        double norm_squared=0.0;
        for (std::size_t i=0;i<m;++i) norm_squared += a[i*n+k]*a[i*n+k];
        r[k*n+k]=std::sqrt(norm_squared);
        for (std::size_t i=0;i<m;++i) q[i*n+k]=a[i*n+k]/r[k*n+k];
        for (std::size_t j=k+1;j<n;++j) {
            r[k*n+j]=0.0;
            for (std::size_t i=0;i<m;++i) r[k*n+j]+=q[i*n+k]*a[i*n+j];
            for (std::size_t i=0;i<m;++i) a[i*n+j]=a[i*n+j]-q[i*n+k]*r[k*n+j];
        }
    }
    for (std::size_t x=0;x<r_cells;++x) staged[x]=r[x];
    for (std::size_t x=0;x<q_cells;++x) staged[r_cells+x]=q[x];
    for (std::size_t x=0;x<total;++x) output[x]=staged[x];
    return static_cast<std::int64_t>(total);
}
