#include <cmath>
#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input_length = 6;
constexpr int max_intervals = 16;
struct Interval { double a, b, value, error; };
constexpr double nodes[7] = {
    0.991455371120812639206854697526329, 0.949107912342758524526189684047851,
    0.864864423359769072789712788640926, 0.741531185599394439863864773280788,
    0.586087235467691130294144838258730, 0.405845151377397166906606412076961,
    0.207784955007898467600689403773245};
constexpr double kw[7] = {
    0.022935322010529224963732008058970, 0.063092092629978553290700663189204,
    0.104790010322250183839876322541518, 0.140653259715525918745189590510238,
    0.169004726639267902826583426598550, 0.190350578064785409913256402421014,
    0.204432940075298892414161999234649};
constexpr double gw[3] = {
    0.129484966168869693270611432679082, 0.279705391489276667901467771423780,
    0.381830050505118944950369775488975};

bool integer_field(double x, int lo, int hi, int& out) noexcept {
    if (!std::isfinite(x) || x < lo || x > hi || std::trunc(x) != x) return false;
    out = static_cast<int>(x);
    return true;
}
double sample(int id, double x) noexcept {
    if (id == 0) return std::exp(4.0 * x);
    if (id == 1) return std::sin(10.0 * x);
    if (id == 2) return 1.0 / (1.0 + 9.0 * x * x);
    const double x2 = x * x, x4 = x2 * x2, x8 = x4 * x4;
    return x8 * x4 * x2;
}
void pair_estimate(int id, double a, double b, double& kronrod, double& gauss) noexcept {
    const double center = (a + b) * 0.5, half = (b - a) * 0.5;
    const double fc = sample(id, center);
    double ks = 0.209482141084727828012999174891714 * fc;
    double gs = 0.417959183673469387755102040816327 * fc;
    for (int i = 0; i < 7; ++i) {
        const double d = half * nodes[i];
        const double pair = sample(id, center - d) + sample(id, center + d);
        ks += kw[i] * pair;
        if (i == 1) gs += gw[0] * pair;
        if (i == 3) gs += gw[1] * pair;
        if (i == 5) gs += gw[2] * pair;
    }
    kronrod = half * ks;
    gauss = half * gs;
}
}

extern "C" std::int64_t adaptive_gauss_kronrod_15_quadrature(
    const double* input, std::size_t input_length, double* output,
    std::size_t output_capacity) noexcept {
    if (input == nullptr || input_length != 5 || input_length > max_input_length) return -1;
    int id, a_micro, b_micro, exponent, limit;
    if (!integer_field(input[0], 0, 3, id) ||
        !integer_field(input[1], -1000000, 1000000, a_micro) ||
        !integer_field(input[2], -1000000, 1000000, b_micro) ||
        !integer_field(input[3], 6, 8, exponent) ||
        !integer_field(input[4], 1, max_intervals, limit) || a_micro > b_micro) return -1;
    if (output == nullptr || output_capacity < 1) return -2;
    const double a = static_cast<double>(a_micro) / 1000000.0;
    const double b = static_cast<double>(b_micro) / 1000000.0;
    if (a == b) { output[0] = 0.0; return 1; }
    Interval intervals[max_intervals];
    double k, g;
    pair_estimate(id, a, b, k, g);
    intervals[0] = {a, b, k, std::abs(k - g)};
    int count = 1;
    double tolerance = 1.0;
    for (int i = 0; i < exponent; ++i) tolerance *= 0.1;
    for (;;) {
        double total = 0.0, error = 0.0;
        for (int i = 0; i < count; ++i) {
            total += intervals[i].value;
            error += intervals[i].error;
        }
        if (error <= tolerance * std::max(1.0, std::abs(total))) {
            if (!std::isfinite(total)) return -1;
            output[0] = total;
            return 1;
        }
        if (count >= limit) return -3;
        int best = 0;
        for (int i = 1; i < count; ++i) {
            if (intervals[i].error > intervals[best].error ||
                (intervals[i].error == intervals[best].error && intervals[i].a < intervals[best].a))
                best = i;
        }
        const double left = intervals[best].a, right = intervals[best].b;
        const double middle = (left + right) * 0.5;
        double lk, lg, rk, rg;
        pair_estimate(id, left, middle, lk, lg);
        pair_estimate(id, middle, right, rk, rg);
        intervals[best] = {left, middle, lk, std::abs(lk - lg)};
        intervals[count++] = {middle, right, rk, std::abs(rk - rg)};
    }
}
