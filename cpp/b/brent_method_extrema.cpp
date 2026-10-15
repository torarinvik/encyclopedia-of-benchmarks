#include <cmath>

namespace {
constexpr double EPSILON = 1.4901161193847656e-8;
constexpr double PI = 3.141592653589793238462643383279502884;
constexpr double TWO_PI = 2.0 * PI;
constexpr double THREE_PI = 3.0 * PI;
constexpr unsigned MAX_ITERATIONS = 256;

double objective_value(double x, double objective_id)
{
    if (objective_id == 0.0) {
        const double offset = x - 2.0;
        return offset * offset;
    }
    return objective_id == 0.5 ? std::cos(x) : -std::cos(x);
}

bool has_valid_bracket(double low, double high, double objective_id)
{
    if (objective_id == 0.0) return low < 2.0 && 2.0 < high;
    if (objective_id == 0.5) return low >= 0.0 && high <= TWO_PI && low < PI && PI < high;
    return objective_id == 1.0 && low >= PI && high <= THREE_PI && low < TWO_PI && TWO_PI < high;
}
}

extern "C" double brent_method_extrema(double start, double end, double objective_id) noexcept
{
    if (!std::isfinite(start) || !std::isfinite(end) || !std::isfinite(objective_id) ||
        start < -10.0 || start > 10.0 || end < -10.0 || end > 10.0) return -1.0;
    double a = start;
    double b = end;
    if (a > b) { const double swap = a; a = b; b = swap; }
    if (b - a <= EPSILON ||
        (objective_id != 0.0 && objective_id != 0.5 && objective_id != 1.0) ||
        !has_valid_bracket(a, b, objective_id)) return -1.0;

    const double golden_ratio = (3.0 - std::sqrt(5.0)) / 2.0;
    double v = a + golden_ratio * (b - a);
    double w = v;
    double x = v;
    double fv = objective_value(v, objective_id);
    double fw = fv;
    double fx = fv;
    double p = 0.0, q = 0.0, r = 0.0;
    double d = 0.0, e = 0.0;

    for (unsigned iteration = 0; iteration < MAX_ITERATIONS; ++iteration) {
        const double midpoint = (a + b) / 2.0;
        const double tolerance = EPSILON * std::abs(x);
        const double tolerance2 = 2.0 * tolerance;
        if (std::abs(e) > tolerance2) {
            r = (x - w) * (fx - fv);
            q = (x - v) * (fx - fw);
            p = (x - v) * q - (x - w) * r;
            q = 2.0 * (q - r);
            if (q > 0.0) p = -p;
            else q = -q;
            r = e;
            e = d;
        }
        if (std::abs(p) < std::abs(0.5 * q * r) && p < q * (b - x)) {
            d = p / q;
            const double u = x + d;
            if (u - a < tolerance2 || b - u < tolerance2)
                d = x < midpoint ? tolerance : -tolerance;
        } else {
            e = (x < midpoint ? b : a) - x;
            d = golden_ratio * e;
        }
        double u;
        if (std::abs(d) >= tolerance) u = d;
        else if (d > 0.0) u = tolerance;
        else u = -tolerance;
        u += x;
        const double fu = objective_value(u, objective_id);
        if (fu <= fx) {
            if (u < x) b = x;
            else a = x;
            v = w; fv = fw;
            w = x; fw = fx;
            x = u; fx = fu;
        } else {
            if (u < x) a = u;
            else b = u;
            if (fu <= fw || x == w) {
                v = w; fv = fw;
                w = u; fw = fu;
            } else if (fu <= fv || v == x || v == w) {
                v = u; fv = fu;
            }
        }
        if (!(std::abs(x - midpoint) > tolerance - (b - a) / 2.0)) return x;
    }
    return x;
}
