#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_n = 8;
constexpr int max_d = 3;
constexpr std::size_t max_input = 37;
constexpr double tolerance = 0.001;
constexpr double epsilon = 0.001;
using Labels = std::array<int, max_n>;
using Alphas = std::array<double, max_n>;
using Points = std::array<std::array<double, max_d>, max_n>;

bool field(double value, int low, int high, int& result) noexcept {
    if (!std::isfinite(value) || value < low || value > high || std::trunc(value) != value)
        return false;
    result = static_cast<int>(value);
    return true;
}

double kernel(const Points& points, int i, int j, int d) noexcept {
    double sum = 0.0;
    for (int k = 0; k < d; ++k) sum += points[i][k] * points[j][k];
    return sum;
}

double decision(int index, const Alphas& alpha, double bias, const Labels& labels,
                const Points& points, int n, int d) noexcept {
    double sum = bias;
    for (int i = 0; i < n; ++i) sum += alpha[i] * labels[i] * kernel(points, i, index, d);
    return sum;
}

double dual(const Alphas& alpha, const Labels& labels, const Points& points,
            int n, int d) noexcept {
    double value = 0.0;
    for (int i = 0; i < n; ++i) value += alpha[i];
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < n; ++j)
            value -= 0.5 * alpha[i] * alpha[j] * labels[i] * labels[j] * kernel(points, i, j, d);
    return value;
}

bool take_step(int i, int j, Alphas& alpha, double& bias, double c,
               const Labels& labels, const Points& points, int n, int d) noexcept {
    if (i == j) return false;
    const int yi = labels[i], yj = labels[j], sign = yi * yj;
    const double old_i = alpha[i], old_j = alpha[j];
    const double ei = decision(i, alpha, bias, labels, points, n, d) - yi;
    const double ej = decision(j, alpha, bias, labels, points, n, d) - yj;
    const double low = yi != yj ? std::max(0.0, old_j - old_i)
                                : std::max(0.0, old_i + old_j - c);
    const double high = yi != yj ? std::min(c, c + old_j - old_i)
                                 : std::min(c, old_i + old_j);
    if (low == high) return false;
    const double kii = kernel(points, i, i, d), kjj = kernel(points, j, j, d);
    const double kij = kernel(points, i, j, d);
    const double curvature = kii + kjj - 2.0 * kij;
    double next_j;
    if (curvature > 0.0) {
        next_j = std::clamp(old_j + yj * (ei - ej) / curvature, low, high);
    } else {
        Alphas trial = alpha;
        trial[i] = old_i + sign * (old_j - low);
        trial[j] = low;
        const double low_score = dual(trial, labels, points, n, d);
        trial[i] = old_i + sign * (old_j - high);
        trial[j] = high;
        const double high_score = dual(trial, labels, points, n, d);
        if (low_score > high_score + epsilon) next_j = low;
        else if (high_score > low_score + epsilon) next_j = high;
        else next_j = old_j;
    }
    if (std::abs(next_j - old_j) < epsilon * (next_j + old_j + epsilon)) return false;
    const double next_i = old_i + sign * (old_j - next_j);
    const double di = next_i - old_i, dj = next_j - old_j;
    const double b_i = bias - ei - yi * di * kii - yj * dj * kij;
    const double b_j = bias - ej - yi * di * kij - yj * dj * kjj;
    if (next_i > 0.0 && next_i < c) bias = b_i;
    else if (next_j > 0.0 && next_j < c) bias = b_j;
    else bias = 0.5 * (b_i + b_j);
    alpha[i] = next_i;
    alpha[j] = next_j;
    return true;
}

bool examine(int j, Alphas& alpha, double& bias, double c, const Labels& labels,
             const Points& points, int n, int d) noexcept {
    const double ej = decision(j, alpha, bias, labels, points, n, d) - labels[j];
    const double r = labels[j] * ej;
    if (!((r < -tolerance && alpha[j] < c) || (r > tolerance && alpha[j] > 0.0))) return false;
    int free_count = 0, preferred = -1;
    double greatest_gap = -1.0;
    for (int i = 0; i < n; ++i) {
        if (alpha[i] > 0.0 && alpha[i] < c) {
            ++free_count;
            const double ei = decision(i, alpha, bias, labels, points, n, d) - labels[i];
            const double gap = std::abs(ei - ej);
            if (gap > greatest_gap) { greatest_gap = gap; preferred = i; }
        }
    }
    if (free_count > 1 && take_step(preferred, j, alpha, bias, c, labels, points, n, d))
        return true;
    for (int i = 0; i < n; ++i)
        if (alpha[i] > 0.0 && alpha[i] < c && take_step(i, j, alpha, bias, c, labels, points, n, d))
            return true;
    for (int i = 0; i < n; ++i)
        if (take_step(i, j, alpha, bias, c, labels, points, n, d)) return true;
    return false;
}
}

extern "C" std::int64_t smo_deterministic_training(
    const double* input, std::size_t input_length, double* output,
    std::size_t output_capacity) noexcept {
    if (input == nullptr || input_length < 4 || input_length > max_input) return -1;
    int n, d, c_milli, pass_cap;
    if (!field(input[0], 2, max_n, n) || !field(input[1], 1, max_d, d) ||
        !field(input[2], 1, 5000, c_milli) || !field(input[3], 1, 16, pass_cap) ||
        input_length != static_cast<std::size_t>(4 + n + n * d)) return -1;
    Labels labels{};
    Alphas alpha{};
    Points points{};
    bool positive = false, negative = false;
    std::size_t at = 4;
    for (int i = 0; i < n; ++i) {
        int label;
        if (!field(input[at++], -1, 1, label) || label == 0) return -1;
        labels[i] = label;
        positive |= label > 0;
        negative |= label < 0;
    }
    if (!positive || !negative) return -1;
    for (int i = 0; i < n; ++i)
        for (int k = 0; k < d; ++k) {
            int coordinate;
            if (!field(input[at++], -32, 32, coordinate)) return -1;
            points[i][k] = coordinate;
        }
    if (output == nullptr || output_capacity < static_cast<std::size_t>(n + 4)) return -2;

    const double c = c_milli / 1000.0;
    double bias = 0.0;
    int changed = 0, passes = 0;
    bool examine_all = true;
    while (passes < pass_cap && (changed > 0 || examine_all)) {
        changed = 0;
        for (int j = 0; j < n; ++j)
            if ((examine_all || (alpha[j] > 0.0 && alpha[j] < c)) &&
                examine(j, alpha, bias, c, labels, points, n, d)) ++changed;
        ++passes;
        if (examine_all) examine_all = false;
        else if (changed == 0) examine_all = true;
    }
    std::array<double, max_n + 4> staged{};
    staged[0] = passes;
    staged[1] = changed;
    staged[2] = passes < pass_cap && changed == 0 && !examine_all ? 1.0 : 0.0;
    std::copy_n(alpha.begin(), n, staged.begin() + 3);
    staged[3 + n] = bias;
    std::copy_n(staged.begin(), n + 4, output);
    return n + 4;
}
