#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxInput = 35, MaxOutput = 38;
constexpr double JacobiTolerance = 1e-14, MinEigenGap = 1e-8;

bool diagonalize(double a[4][4], double vectors[4][4], std::size_t n, double values[4]) {
    for (std::size_t i = 0; i < n; ++i) for (std::size_t j = 0; j < n; ++j)
        vectors[i][j] = i == j ? 1.0 : 0.0;
    bool converged = false;
    for (std::size_t sweep = 0; sweep <= 64; ++sweep) {
        double largest = 0.0;
        for (std::size_t p = 0; p < n; ++p) for (std::size_t q = p + 1; q < n; ++q)
            largest = std::max(largest, std::abs(a[p][q]));
        if (largest <= JacobiTolerance) { converged = true; break; }
        if (sweep == 64) break;
        for (std::size_t p = 0; p < n; ++p) for (std::size_t q = p + 1; q < n; ++q) {
            const double apq = a[p][q];
            if (std::abs(apq) <= JacobiTolerance) continue;
            const double tau = (a[q][q] - a[p][p]) / (2.0 * apq);
            const double sign = tau >= 0.0 ? 1.0 : -1.0;
            const double t = sign / (std::abs(tau) + std::sqrt(1.0 + tau * tau));
            const double c = 1.0 / std::sqrt(1.0 + t * t), s = t * c;
            const double app = a[p][p], aqq = a[q][q];
            a[p][p] = app - t * apq; a[q][q] = aqq + t * apq;
            a[p][q] = a[q][p] = 0.0;
            for (std::size_t r = 0; r < n; ++r) {
                if (r != p && r != q) {
                    const double arp = a[r][p], arq = a[r][q];
                    a[r][p] = a[p][r] = c * arp - s * arq;
                    a[r][q] = a[q][r] = s * arp + c * arq;
                }
                const double vrp = vectors[r][p], vrq = vectors[r][q];
                vectors[r][p] = c * vrp - s * vrq;
                vectors[r][q] = s * vrp + c * vrq;
            }
        }
    }
    if (!converged) return false;
    for (std::size_t i = 0; i < n; ++i) values[i] = a[i][i];
    for (std::size_t i = 0; i < n; ++i) for (std::size_t j = i + 1; j < n; ++j)
        if (values[j] > values[i]) {
            std::swap(values[i], values[j]);
            for (std::size_t r = 0; r < n; ++r) std::swap(vectors[r][i], vectors[r][j]);
        }
    return true;
}
}

extern "C" std::int64_t principle_component_analysis(const double* input, std::size_t input_length,
                                                       double* output, std::size_t output_capacity) {
    if (!input || input_length < 3 || input_length > MaxInput) return -1;
    for (std::size_t i = 0; i < input_length; ++i) if (!std::isfinite(input[i])) return -1;
    if (input[0] < 3 || input[0] > 8 || std::trunc(input[0]) != input[0] ||
        input[1] < 2 || input[1] > 4 || std::trunc(input[1]) != input[1] ||
        input[2] < 1 || input[2] > 4 || std::trunc(input[2]) != input[2]) return -1;
    const std::size_t samples = static_cast<std::size_t>(input[0]);
    const std::size_t features = static_cast<std::size_t>(input[1]);
    const std::size_t components = static_cast<std::size_t>(input[2]);
    if (samples <= features || components > features || input_length != 3 + samples * features) return -1;
    double rows[8][4] = {}, means[4] = {};
    for (std::size_t r = 0; r < samples; ++r) for (std::size_t c = 0; c < features; ++c) {
        const double x = input[3 + r * features + c];
        if (std::trunc(x) != x || x < -9 || x > 9) return -1;
        rows[r][c] = x; means[c] += x;
        if (!std::isfinite(means[c])) return -1;
    }
    for (std::size_t c = 0; c < features; ++c) means[c] /= static_cast<double>(samples);
    double variances[4] = {}, standardized[8][4] = {}, pca_means[4] = {};
    for (std::size_t r = 0; r < samples; ++r) for (std::size_t c = 0; c < features; ++c) {
        const double delta = rows[r][c] - means[c]; variances[c] += delta * delta;
    }
    double scales[4];
    for (std::size_t c = 0; c < features; ++c) {
        variances[c] /= static_cast<double>(samples);
        if (!(variances[c] > 0) || !std::isfinite(variances[c])) return -1;
        scales[c] = std::sqrt(variances[c]);
    }
    for (std::size_t r = 0; r < samples; ++r) for (std::size_t c = 0; c < features; ++c) {
        standardized[r][c] = (rows[r][c] - means[c]) / scales[c];
        if (!std::isfinite(standardized[r][c])) return -1;
        pca_means[c] += standardized[r][c];
    }
    for (std::size_t c = 0; c < features; ++c) pca_means[c] /= static_cast<double>(samples);
    double centered[8][4] = {}, covariance[4][4] = {};
    for (std::size_t r = 0; r < samples; ++r) for (std::size_t c = 0; c < features; ++c) {
        centered[r][c] = standardized[r][c] - pca_means[c];
        if (!std::isfinite(centered[r][c])) return -1;
    }
    for (std::size_t i = 0; i < features; ++i) for (std::size_t j = i; j < features; ++j) {
        double sum = 0.0;
        for (std::size_t r = 0; r < samples; ++r) sum += centered[r][i] * centered[r][j];
        covariance[i][j] = covariance[j][i] = sum / static_cast<double>(samples - 1);
        if (!std::isfinite(covariance[i][j])) return -1;
    }
    double vectors[4][4] = {}, eigenvalues[4] = {};
    if (!diagonalize(covariance, vectors, features, eigenvalues)) return -1;
    for (std::size_t i = 0; i < features; ++i)
        if (!(eigenvalues[i] > 0) || !std::isfinite(eigenvalues[i]) ||
            (i + 1 < features && eigenvalues[i] - eigenvalues[i + 1] <= MinEigenGap)) return -1;
    double total = 0.0;
    for (std::size_t i = 0; i < features; ++i) total += eigenvalues[i];
    if (!(total > 0) || !std::isfinite(total)) return -1;
    double scores[4][8] = {};
    for (std::size_t k = 0; k < components; ++k) {
        for (std::size_t r = 0; r < samples; ++r) for (std::size_t c = 0; c < features; ++c)
            scores[k][r] += centered[r][c] * vectors[c][k];
        std::size_t pivot = 0;
        for (std::size_t r = 1; r < samples; ++r)
            if (std::abs(scores[k][r]) > std::abs(scores[k][pivot])) pivot = r;
        if (scores[k][pivot] < 0) for (std::size_t r = 0; r < samples; ++r) scores[k][r] = -scores[k][r];
    }
    double staged[MaxOutput] = {}; staged[0] = static_cast<double>(samples); staged[1] = static_cast<double>(components);
    std::size_t pos = 2;
    for (std::size_t r = 0; r < samples; ++r) for (std::size_t k = 0; k < components; ++k) staged[pos++] = scores[k][r];
    for (std::size_t k = 0; k < components; ++k) staged[pos++] = eigenvalues[k] / total;
    for (std::size_t i = 0; i < pos; ++i) if (!std::isfinite(staged[i])) return -1;
    if (!output || output_capacity < pos) return -2;
    std::copy(staged, staged + pos, output);
    return static_cast<std::int64_t>(pos);
}
