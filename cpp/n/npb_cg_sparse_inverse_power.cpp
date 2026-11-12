#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t kMaxN = 32;
constexpr std::size_t kMaxOuter = 8;
constexpr std::size_t kMaxSteps = 25;
constexpr std::int64_t kMaxMicro = 1'000'000'000;
constexpr double kScale = 1'000'000.0;

void write_f64_le(std::uint8_t* out, std::size_t offset, double value) {
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    for (std::size_t byte = 0; byte < 8; ++byte)
        out[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}

void matvec(std::size_t n, const std::int64_t* v, const double* x, double* y) {
    const std::size_t row_ptr = 5, columns = row_ptr + n + 1;
    const std::size_t entries = columns + static_cast<std::size_t>(v[4]);
    for (std::size_t row = 0; row < n; ++row) {
        double sum = 0.0;
        for (std::size_t edge = static_cast<std::size_t>(v[row_ptr + row]);
             edge < static_cast<std::size_t>(v[row_ptr + row + 1]); ++edge)
            sum += static_cast<double>(v[entries + edge]) / kScale *
                   x[static_cast<std::size_t>(v[columns + edge])];
        y[row] = sum;
    }
}

bool valid(const std::int64_t* v, std::size_t length, std::size_t& n,
           std::size_t& outer_count, std::size_t& steps, std::size_t& nnz) {
    if (v == nullptr || length < 8 || v[0] < 1 || v[0] > static_cast<std::int64_t>(kMaxN) ||
        v[1] < 1 || v[1] > static_cast<std::int64_t>(kMaxOuter) ||
        v[2] < 1 || v[2] > static_cast<std::int64_t>(kMaxSteps) || v[2] > v[0] ||
        v[3] < -kMaxMicro || v[3] > kMaxMicro || v[4] < v[0] || v[4] > 6 * v[0]) return false;
    n = static_cast<std::size_t>(v[0]); outer_count = static_cast<std::size_t>(v[1]);
    steps = static_cast<std::size_t>(v[2]); nnz = static_cast<std::size_t>(v[4]);
    if (length != n + 6 + 2 * nnz) return false;
    const std::size_t rp = 5, col = rp + n + 1, val = col + nnz;
    if (v[rp] != 0 || v[rp + n] != static_cast<std::int64_t>(nnz)) return false;
    for (std::size_t row = 0; row < n; ++row) {
        if (v[rp + row] < 0 || v[rp + row] >= v[rp + row + 1] ||
            v[rp + row + 1] > static_cast<std::int64_t>(nnz)) return false;
        std::int64_t diagonal = 0, off_sum = 0, previous = -1;
        for (std::size_t edge = static_cast<std::size_t>(v[rp + row]);
             edge < static_cast<std::size_t>(v[rp + row + 1]); ++edge) {
            const std::int64_t c = v[col + edge], a = v[val + edge];
            if (c < 0 || c >= static_cast<std::int64_t>(n) || c <= previous ||
                a == 0 || a < -kMaxMicro || a > kMaxMicro) return false;
            previous = c;
            if (static_cast<std::size_t>(c) == row) diagonal = a;
            else off_sum += a < 0 ? -a : a;
        }
        if (diagonal <= 0 || diagonal <= off_sum) return false;
    }
    for (std::size_t row = 0; row < n; ++row) {
        for (std::size_t edge = static_cast<std::size_t>(v[rp + row]);
             edge < static_cast<std::size_t>(v[rp + row + 1]); ++edge) {
            const std::size_t c = static_cast<std::size_t>(v[col + edge]);
            bool found = false;
            for (std::size_t reverse = static_cast<std::size_t>(v[rp + c]);
                 reverse < static_cast<std::size_t>(v[rp + c + 1]); ++reverse) {
                if (static_cast<std::size_t>(v[col + reverse]) == row && v[val + reverse] == v[val + edge]) {
                    found = true; break;
                }
            }
            if (!found) return false;
        }
    }
    return true;
}
}

extern "C" std::int64_t npb_cg_sparse_inverse_power(const std::int64_t* values,
        std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    std::size_t n, outer_count, steps, nnz;
    if (!valid(values, length, n, outer_count, steps, nnz)) return -1;
    const std::size_t output_bytes = outer_count * 16;
    if (output == nullptr || capacity < output_bytes) return -2;
    double x[kMaxN], z[kMaxN], r[kMaxN], p[kMaxN], q[kMaxN], az[kMaxN];
    for (std::size_t i = 0; i < n; ++i) x[i] = 1.0;
    for (std::size_t outer = 0; outer < outer_count; ++outer) {
        double rhs2 = 0.0;
        for (std::size_t i = 0; i < n; ++i) {
            z[i] = 0.0; r[i] = x[i]; p[i] = x[i]; rhs2 += r[i] * r[i];
        }
        double rr = rhs2;
        for (std::size_t step = 0; step < steps && rr > 0.0; ++step) {
            matvec(n, values, p, q);
            double denom = 0.0;
            for (std::size_t i = 0; i < n; ++i) denom += p[i] * q[i];
            if (!(denom > 0.0) || !std::isfinite(denom)) return -1;
            const double alpha = rr / denom;
            for (std::size_t i = 0; i < n; ++i) { z[i] += alpha * p[i]; r[i] -= alpha * q[i]; }
            double next = 0.0;
            for (std::size_t i = 0; i < n; ++i) next += r[i] * r[i];
            if (next <= rhs2 * 1.0e-28) { rr = next; break; }
            const double beta = next / rr;
            for (std::size_t i = 0; i < n; ++i) p[i] = r[i] + beta * p[i];
            rr = next;
        }
        matvec(n, values, z, az);
        double explicit2 = 0.0, dot = 0.0, z2 = 0.0;
        for (std::size_t i = 0; i < n; ++i) {
            const double difference = x[i] - az[i];
            explicit2 += difference * difference; dot += x[i] * z[i]; z2 += z[i] * z[i];
        }
        if (!(dot > 0.0) || !(z2 > 0.0) || !std::isfinite(dot) || !std::isfinite(z2)) return -1;
        const double estimate = static_cast<double>(values[3]) / kScale + 1.0 / dot;
        const double residual_norm = std::sqrt(explicit2);
        if (!std::isfinite(estimate) || !std::isfinite(residual_norm)) return -1;
        write_f64_le(output, outer * 16, estimate);
        write_f64_le(output, outer * 16 + 8, residual_norm);
        const double z_norm = std::sqrt(z2);
        for (std::size_t i = 0; i < n; ++i) x[i] = z[i] / z_norm;
    }
    return static_cast<std::int64_t>(output_bytes);
}
