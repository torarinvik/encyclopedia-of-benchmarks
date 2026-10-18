#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_SAMPLES 8u
#define MAX_FEATURES 4u
#define MAX_INPUT 35u
#define MAX_OUTPUT 38u
#define MAX_SWEEPS 64u
#define JACOBI_TOLERANCE 1e-14
#define MIN_EIGENGAP 1e-8

static int diagonalize(double a[4][4], double v[4][4], size_t n, double d[4]) {
    for (size_t i = 0; i < n; ++i) for (size_t j = 0; j < n; ++j)
        v[i][j] = i == j ? 1.0 : 0.0;
    int converged = 0;
    for (size_t sweep = 0; sweep <= MAX_SWEEPS; ++sweep) {
        double largest = 0.0;
        for (size_t p = 0; p < n; ++p) for (size_t q = p + 1; q < n; ++q)
            if (fabs(a[p][q]) > largest) largest = fabs(a[p][q]);
        if (largest <= JACOBI_TOLERANCE) { converged = 1; break; }
        if (sweep == MAX_SWEEPS) break;
        for (size_t p = 0; p < n; ++p) for (size_t q = p + 1; q < n; ++q) {
            double apq = a[p][q];
            if (fabs(apq) <= JACOBI_TOLERANCE) continue;
            double tau = (a[q][q] - a[p][p]) / (2.0 * apq);
            double sign = tau >= 0.0 ? 1.0 : -1.0;
            double t = sign / (fabs(tau) + sqrt(1.0 + tau * tau));
            double c = 1.0 / sqrt(1.0 + t * t), s = t * c;
            double app = a[p][p], aqq = a[q][q];
            a[p][p] = app - t * apq; a[q][q] = aqq + t * apq;
            a[p][q] = a[q][p] = 0.0;
            for (size_t r = 0; r < n; ++r) {
                if (r != p && r != q) {
                    double arp = a[r][p], arq = a[r][q];
                    a[r][p] = a[p][r] = c * arp - s * arq;
                    a[r][q] = a[q][r] = s * arp + c * arq;
                }
                double vrp = v[r][p], vrq = v[r][q];
                v[r][p] = c * vrp - s * vrq;
                v[r][q] = s * vrp + c * vrq;
            }
        }
    }
    if (!converged) return 0;
    for (size_t i = 0; i < n; ++i) d[i] = a[i][i];
    for (size_t i = 0; i < n; ++i) for (size_t j = i + 1; j < n; ++j)
        if (d[j] > d[i]) {
            double temp = d[i]; d[i] = d[j]; d[j] = temp;
            for (size_t row = 0; row < n; ++row) {
                temp = v[row][i]; v[row][i] = v[row][j]; v[row][j] = temp;
            }
        }
    return 1;
}

int64_t principle_component_analysis(const double *input, size_t input_length,
                                    double *output, size_t output_capacity) {
    if (input == NULL || input_length < 3 || input_length > MAX_INPUT) return -1;
    for (size_t i = 0; i < input_length; ++i) if (!isfinite(input[i])) return -1;
    if (input[0] < 3.0 || input[0] > MAX_SAMPLES || trunc(input[0]) != input[0] ||
        input[1] < 2.0 || input[1] > MAX_FEATURES || trunc(input[1]) != input[1] ||
        input[2] < 1.0 || input[2] > MAX_FEATURES || trunc(input[2]) != input[2]) return -1;
    size_t samples = (size_t)input[0], features = (size_t)input[1], components = (size_t)input[2];
    if (samples <= features || components > features || input_length != 3 + samples * features) return -1;
    double rows[8][4] = {{0}}, means[4] = {0};
    for (size_t r = 0; r < samples; ++r) for (size_t c = 0; c < features; ++c) {
        double x = input[3 + r * features + c];
        if (trunc(x) != x || x < -9.0 || x > 9.0) return -1;
        rows[r][c] = x; means[c] += x;
        if (!isfinite(means[c])) return -1;
    }
    for (size_t c = 0; c < features; ++c) means[c] /= (double)samples;
    double variances[4] = {0}, standardized[8][4] = {{0}}, pca_means[4] = {0};
    for (size_t r = 0; r < samples; ++r) for (size_t c = 0; c < features; ++c) {
        double delta = rows[r][c] - means[c];
        variances[c] += delta * delta;
        if (!isfinite(variances[c])) return -1;
    }
    double scales[4];
    for (size_t c = 0; c < features; ++c) {
        variances[c] /= (double)samples;
        if (!(variances[c] > 0.0) || !isfinite(variances[c])) return -1;
        scales[c] = sqrt(variances[c]);
    }
    for (size_t r = 0; r < samples; ++r) for (size_t c = 0; c < features; ++c) {
        standardized[r][c] = (rows[r][c] - means[c]) / scales[c];
        if (!isfinite(standardized[r][c])) return -1;
        pca_means[c] += standardized[r][c];
    }
    for (size_t c = 0; c < features; ++c) pca_means[c] /= (double)samples;
    double centered[8][4] = {{0}}, covariance[4][4] = {{0}};
    for (size_t r = 0; r < samples; ++r) for (size_t c = 0; c < features; ++c) {
        centered[r][c] = standardized[r][c] - pca_means[c];
        if (!isfinite(centered[r][c])) return -1;
    }
    for (size_t i = 0; i < features; ++i) for (size_t j = i; j < features; ++j) {
        double sum = 0.0;
        for (size_t r = 0; r < samples; ++r) sum += centered[r][i] * centered[r][j];
        covariance[i][j] = covariance[j][i] = sum / (double)(samples - 1);
        if (!isfinite(covariance[i][j])) return -1;
    }
    double eigenvectors[4][4] = {{0}}, eigenvalues[4];
    if (!diagonalize(covariance, eigenvectors, features, eigenvalues)) return -1;
    for (size_t i = 0; i < features; ++i) {
        if (!(eigenvalues[i] > 0.0) || !isfinite(eigenvalues[i])) return -1;
        if (i + 1 < features && eigenvalues[i] - eigenvalues[i + 1] <= MIN_EIGENGAP) return -1;
    }
    double total_variance = 0.0;
    for (size_t i = 0; i < features; ++i) total_variance += eigenvalues[i];
    if (!(total_variance > 0.0) || !isfinite(total_variance)) return -1;
    double scores[4][8] = {{0}};
    for (size_t k = 0; k < components; ++k) {
        for (size_t r = 0; r < samples; ++r)
            for (size_t c = 0; c < features; ++c) scores[k][r] += centered[r][c] * eigenvectors[c][k];
        size_t pivot = 0;
        for (size_t r = 1; r < samples; ++r) if (fabs(scores[k][r]) > fabs(scores[k][pivot])) pivot = r;
        if (scores[k][pivot] < 0.0) for (size_t r = 0; r < samples; ++r) scores[k][r] = -scores[k][r];
    }
    double staged[MAX_OUTPUT] = {0};
    staged[0] = (double)samples; staged[1] = (double)components;
    size_t pos = 2;
    for (size_t r = 0; r < samples; ++r) for (size_t k = 0; k < components; ++k)
        staged[pos++] = scores[k][r];
    for (size_t k = 0; k < components; ++k) staged[pos++] = eigenvalues[k] / total_variance;
    for (size_t i = 0; i < pos; ++i) if (!isfinite(staged[i])) return -1;
    if (output == NULL || output_capacity < pos) return -2;
    for (size_t i = 0; i < pos; ++i) output[i] = staged[i];
    return (int64_t)pos;
}
