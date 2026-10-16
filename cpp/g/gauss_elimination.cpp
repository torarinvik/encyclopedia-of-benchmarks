#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
void put_f64_le(std::uint8_t *out, std::size_t off, double value) noexcept {
    const auto bits = [&] { union { double f; std::uint64_t u; } v{value}; return v.u; }();
    for (std::size_t i = 0; i < 8; ++i) out[off + i] = static_cast<std::uint8_t>(bits >> (8 * i));
}
}

extern "C" std::int64_t gauss_elimination(const std::int64_t *input, std::size_t length,
                                             std::uint8_t *output, std::size_t capacity) noexcept {
    if (!input || length < 1 || input[0] < 2 || input[0] > 8) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != 1 + n*n + n) return -1;
    float m[8][9]{};
    for (std::size_t i=0; i<n*n+n; ++i) if (input[i+1] < -100 || input[i+1] > 100) return -1;
    for (std::size_t r=0; r<n; ++r) {
        for (std::size_t c=0; c<n; ++c) m[r][c] = static_cast<float>(input[1+r*n+c]);
        m[r][n] = static_cast<float>(input[1+n*n+r]);
    }
    for (std::size_t i=0; i+1<n; ++i) {
        std::size_t pivot=i;
        for (std::size_t j=i; j<n; ++j) if (std::fabs(m[j][i]) > std::fabs(m[pivot][i])) pivot=j;
        if (m[pivot][i] == 0.0f) return -1;
        if (pivot != i) for (std::size_t l=0; l<=n; ++l) { float t=m[i][l]; m[i][l]=m[pivot][l]; m[pivot][l]=t; }
        for (std::size_t j=i+1; j<n; ++j) {
            const float tmp = -(m[j][i] / m[i][i]);
            for (std::size_t l=0; l<=n; ++l) m[j][l] = m[j][l] + m[i][l]*tmp;
        }
    }
    if (m[n-1][n-1] == 0.0f) return -1;
    if (!output || capacity < n*8) return -2;
    float ans[8]{};
    for (std::size_t k=n; k-- > 0;) {
        float mul=0.0f;
        for (std::size_t l=n; l-- > k+1;) mul = mul + m[k][l]*ans[l];
        ans[k]=(m[k][n]-mul)/m[k][k];
    }
    for (std::size_t i=0; i<n; ++i) put_f64_le(output, i*8, static_cast<double>(std::nearbyint(static_cast<double>(ans[i])*100.0)/100.0));
    return static_cast<std::int64_t>(n*8);
}
