#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t kN = 32, kCoarse = 16, kSteps = 12, kRowNnz = 6;
constexpr std::int64_t kMicro = 1'000'000'000;
constexpr double kScale = 1'000'000.0;
constexpr std::size_t kRp = 3;
std::size_t col_at(std::size_t n) { return 4 + n; }
std::size_t val_at(std::size_t n, std::size_t nnz) { return 4 + n + nnz; }
std::size_t rhs_at(std::size_t n, std::size_t nnz) { return val_at(n, nnz) + nnz; }

bool valid(const std::int64_t* v, std::size_t length, std::size_t& n,
           std::size_t& steps, std::size_t& nnz, double* diagonal) {
    if (v == nullptr || length < 8 || length > 452 || v[0] < 1 || v[0] > static_cast<std::int64_t>(kN) ||
        v[1] < 1 || v[1] > static_cast<std::int64_t>(kSteps) || v[1] > v[0] ||
        v[2] < v[0] || v[2] > 6 * v[0]) return false;
    n = static_cast<std::size_t>(v[0]); steps = static_cast<std::size_t>(v[1]);
    nnz = static_cast<std::size_t>(v[2]);
    if (length != 4 + 2 * n + 2 * nnz) return false;
    const std::size_t col = col_at(n), val = val_at(n, nnz), rhs = rhs_at(n, nnz);
    if (v[kRp] != 0 || v[kRp + n] != static_cast<std::int64_t>(nnz)) return false;
    for (std::size_t row = 0; row < n; ++row) {
        const auto begin = v[kRp + row], end = v[kRp + row + 1];
        if (begin < 0 || begin >= end || end > static_cast<std::int64_t>(nnz) || end - begin > static_cast<std::int64_t>(kRowNnz)) return false;
        std::int64_t diag = 0, off = 0, previous = -1;
        for (std::size_t edge = static_cast<std::size_t>(begin); edge < static_cast<std::size_t>(end); ++edge) {
            const auto c = v[col + edge], a = v[val + edge];
            if (c < 0 || c >= static_cast<std::int64_t>(n) || c <= previous || a == 0 || a < -kMicro || a > kMicro) return false;
            previous = c;
            if (static_cast<std::size_t>(c) == row) diag = a;
            else off += a < 0 ? -a : a;
        }
        if (diag <= 0 || diag <= off || v[rhs + row] < -kMicro || v[rhs + row] > kMicro) return false;
        diagonal[row] = static_cast<double>(diag) / kScale;
    }
    for (std::size_t row = 0; row < n; ++row)
        for (std::size_t edge = static_cast<std::size_t>(v[kRp + row]); edge < static_cast<std::size_t>(v[kRp + row + 1]); ++edge) {
            const std::size_t c = static_cast<std::size_t>(v[col + edge]);
            bool found = false;
            for (std::size_t rev = static_cast<std::size_t>(v[kRp + c]); rev < static_cast<std::size_t>(v[kRp + c + 1]); ++rev)
                if (static_cast<std::size_t>(v[col + rev]) == row && v[val + rev] == v[val + edge]) { found = true; break; }
            if (!found) return false;
        }
    return true;
}

void matvec(std::size_t n, std::size_t nnz, const std::int64_t* v, const double* x, double* y) {
    const auto col = col_at(n), val = val_at(n, nnz);
    for (std::size_t row = 0; row < n; ++row) {
        double sum = 0.0;
        for (std::size_t edge = static_cast<std::size_t>(v[kRp + row]); edge < static_cast<std::size_t>(v[kRp + row + 1]); ++edge)
            sum += static_cast<double>(v[val + edge]) / kScale * x[static_cast<std::size_t>(v[col + edge])];
        y[row] = sum;
    }
}

bool coarse_solve(std::size_t n, std::size_t nnz, const std::int64_t* v,
                  const double* rhs, double* solution) {
    const std::size_t cn = (n + 1) / 2, col = col_at(n), val = val_at(n, nnz);
    double a[kCoarse][kCoarse] = {}, l[kCoarse][kCoarse] = {};
    for (std::size_t row = 0; row < n; ++row)
        for (std::size_t edge = static_cast<std::size_t>(v[kRp + row]); edge < static_cast<std::size_t>(v[kRp + row + 1]); ++edge)
            a[row / 2][static_cast<std::size_t>(v[col + edge]) / 2] += static_cast<double>(v[val + edge]) / kScale;
    for (std::size_t i = 0; i < cn; ++i) for (std::size_t j = 0; j <= i; ++j) {
        double value = a[i][j];
        for (std::size_t q = 0; q < j; ++q) value -= l[i][q] * l[j][q];
        if (i == j) { if (!(value > 0.0) || !std::isfinite(value)) return false; l[i][j] = std::sqrt(value); }
        else l[i][j] = value / l[j][j];
    }
    double y[kCoarse] = {};
    for (std::size_t i = 0; i < cn; ++i) { double t = rhs[i]; for (std::size_t j = 0; j < i; ++j) t -= l[i][j] * y[j]; y[i] = t / l[i][i]; }
    for (std::size_t ii = cn; ii-- > 0;) { double t = y[ii]; for (std::size_t j = ii + 1; j < cn; ++j) t -= l[j][ii] * solution[j]; solution[ii] = t / l[ii][ii]; }
    return true;
}

bool precondition(std::size_t n, std::size_t nnz, const std::int64_t* v,
                  const double* d, const double* r, double* z) {
    const auto col = col_at(n), val = val_at(n, nnz);
    double pre[kN] = {}, product[kN] = {}, coarse_rhs[kCoarse] = {}, coarse_x[kCoarse] = {};
    double middle[kN] = {}, post_r[kN] = {}, post[kN] = {};
    for (std::size_t row = 0; row < n; ++row) {
        double t = r[row];
        for (std::size_t edge = static_cast<std::size_t>(v[kRp + row]); edge < static_cast<std::size_t>(v[kRp + row + 1]); ++edge) {
            const auto c = static_cast<std::size_t>(v[col + edge]);
            if (c < row) t -= static_cast<double>(v[val + edge]) / kScale * pre[c];
        }
        pre[row] = t / d[row];
    }
    matvec(n, nnz, v, pre, product);
    for (std::size_t row = 0; row < n; ++row) coarse_rhs[row / 2] += r[row] - product[row];
    if (!coarse_solve(n, nnz, v, coarse_rhs, coarse_x)) return false;
    for (std::size_t row = 0; row < n; ++row) middle[row] = pre[row] + coarse_x[row / 2];
    matvec(n, nnz, v, middle, product);
    for (std::size_t row = 0; row < n; ++row) post_r[row] = r[row] - product[row];
    for (std::size_t ii = n; ii-- > 0;) {
        double t = post_r[ii];
        for (std::size_t edge = static_cast<std::size_t>(v[kRp + ii]); edge < static_cast<std::size_t>(v[kRp + ii + 1]); ++edge) {
            const auto c = static_cast<std::size_t>(v[col + edge]);
            if (c > ii) t -= static_cast<double>(v[val + edge]) / kScale * post[c];
        }
        post[ii] = t / d[ii];
    }
    for (std::size_t row = 0; row < n; ++row) z[row] = middle[row] + post[row];
    return true;
}

void write_f64_le(std::uint8_t* out, std::size_t offset, double x) {
    std::uint64_t bits; std::memcpy(&bits, &x, sizeof(bits));
    for (std::size_t i = 0; i < 8; ++i) out[offset + i] = static_cast<std::uint8_t>(bits >> (8 * i));
}
}

extern "C" std::int64_t hpcg_profile(const std::int64_t* values, std::size_t length,
                                      std::uint8_t* output, std::size_t capacity) noexcept {
    std::size_t n, steps, nnz; double d[kN] = {};
    if (!valid(values, length, n, steps, nnz, d)) return -1;
    const std::size_t bytes = 8 * (n + 1);
    if (output == nullptr || capacity < bytes) return -2;
    const auto rhs = rhs_at(n, nnz);
    double b[kN] = {}, x[kN] = {}, r[kN] = {}, z[kN] = {}, p[kN] = {}, q[kN] = {}, ax[kN] = {};
    double b2 = 0.0;
    for (std::size_t i = 0; i < n; ++i) { b[i] = static_cast<double>(values[rhs + i]) / kScale; r[i] = b[i]; b2 += b[i] * b[i]; }
    if (b2 > 0.0) {
        if (!precondition(n, nnz, values, d, r, z)) return -1;
        std::memcpy(p, z, n * sizeof(double));
        double rho = 0.0; for (std::size_t i = 0; i < n; ++i) rho += r[i] * z[i];
        if (!(rho > 0.0) || !std::isfinite(rho)) return -1;
        for (std::size_t step = 0; step < steps; ++step) {
            matvec(n, nnz, values, p, q);
            double curv = 0.0; for (std::size_t i = 0; i < n; ++i) curv += p[i] * q[i];
            if (!(curv > 0.0) || !std::isfinite(curv)) return -1;
            const double alpha = rho / curv;
            for (std::size_t i = 0; i < n; ++i) { x[i] += alpha * p[i]; r[i] -= alpha * q[i]; }
            double r2 = 0.0; for (std::size_t i = 0; i < n; ++i) r2 += r[i] * r[i];
            if (r2 <= b2 * 1.0e-28) break;
            double next_z[kN] = {}; if (!precondition(n, nnz, values, d, r, next_z)) return -1;
            double next_rho = 0.0; for (std::size_t i = 0; i < n; ++i) next_rho += r[i] * next_z[i];
            if (!(next_rho > 0.0) || !std::isfinite(next_rho)) return -1;
            const double beta = next_rho / rho;
            for (std::size_t i = 0; i < n; ++i) { z[i] = next_z[i]; p[i] = z[i] + beta * p[i]; }
            rho = next_rho;
        }
    }
    matvec(n, nnz, values, x, ax);
    double residual2 = 0.0;
    for (std::size_t i = 0; i < n; ++i) { const double e = b[i] - ax[i]; residual2 += e * e; if (!std::isfinite(x[i])) return -1; write_f64_le(output, 8 * i, x[i]); }
    const double norm = std::sqrt(residual2); if (!std::isfinite(norm)) return -1;
    write_f64_le(output, 8 * n, norm);
    return static_cast<std::int64_t>(bytes);
}
