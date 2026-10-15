#include <cmath>

namespace {
constexpr double invalid_result = -1.0e300;
constexpr double tolerance = 1.0e-8;

double function_value(int function_id, double x)
{
    if (function_id == 0) return x * x * x - x - 2.0;
    if (function_id == 1) return x * x + 1.0;
    return x * x - 4.0 * x + 3.0;
}

void swap_double(double &left, double &right)
{
    const double temporary = left;
    left = right;
    right = temporary;
}
}

extern "C" double brent_method(double function_id_value, double left, double right) noexcept
{
    if ((function_id_value != 0.0 && function_id_value != 1.0 && function_id_value != 2.0) ||
        !(left >= -4.0 && left <= 4.0) || !(right >= -4.0 && right <= 4.0) || left >= right)
        return invalid_result;
    const int function_id = static_cast<int>(function_id_value);
    double f_left = function_value(function_id, left);
    double f_right = function_value(function_id, right);
    if (f_left * f_right >= 0.0) return invalid_result;
    if (std::abs(f_left) < std::abs(f_right)) {
        swap_double(left, right);
        swap_double(f_left, f_right);
    }

    double c = left;
    double f_c = f_left;
    double d = right - left;
    for (int iteration = 0; iteration < 100; ++iteration) {
        if (f_right == 0.0) return right;
        double candidate;
        if (f_c != f_left && f_c != f_right) {
            candidate = left * f_right * f_c / ((f_left - f_right) * (f_left - f_c)) +
                        right * f_left * f_c / ((f_right - f_left) * (f_right - f_c)) +
                        c * f_left * f_right / ((f_c - f_left) * (f_c - f_right));
        } else {
            candidate = right - f_right * (right - left) / (f_right - f_left);
        }

        const double quarter = (3.0 * left + right) / 4.0;
        const bool outside = right > left ? !(quarter < candidate && candidate < right)
                                          : !(right < candidate && candidate < quarter);
        const bool use_bisection = outside ||
            (iteration > 1 && std::abs(candidate - right) >= std::abs(right - c) / 2.0) ||
            (iteration <= 1 && std::abs(candidate - right) >= std::abs(c - d) / 2.0) ||
            (iteration > 1 && std::abs(right - c) < tolerance) ||
            (iteration <= 1 && std::abs(c - d) < tolerance);
        if (use_bisection) {
            candidate = (left + right) / 2.0;
            d = right - left;
        }

        const double f_candidate = function_value(function_id, candidate);
        d = c;
        c = right;
        f_c = f_right;
        if (f_left * f_candidate < 0.0) {
            right = candidate;
            f_right = f_candidate;
        } else {
            left = candidate;
            f_left = f_candidate;
        }
        if (std::abs(f_left) < std::abs(f_right)) {
            swap_double(left, right);
            swap_double(f_left, f_right);
        }
        if (std::abs(right - left) < tolerance) return right;
    }
    return right;
}
