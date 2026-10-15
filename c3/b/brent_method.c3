module brent_method;

extern fn double fabs(double value);

const double INVALID_RESULT = -1.0e300;
const double TOLERANCE = 1.0e-8;

fn double function_value(int function_id, double x) {
    if (function_id == 0) return x * x * x - x - 2.0;
    if (function_id == 1) return x * x + 1.0;
    return x * x - 4.0 * x + 3.0;
}

fn void swap_double(double* left, double* right) {
    double temporary = *left;
    *left = *right;
    *right = temporary;
}

fn double brent_method(double function_id_value, double left, double right) @export("brent_method") {
    if ((function_id_value != 0.0 && function_id_value != 1.0 && function_id_value != 2.0) ||
        !(left >= -4.0 && left <= 4.0) || !(right >= -4.0 && right <= 4.0) || left >= right) return INVALID_RESULT;
    int function_id = (int)function_id_value;
    double f_left = function_value(function_id, left);
    double f_right = function_value(function_id, right);
    if (f_left * f_right >= 0.0) return INVALID_RESULT;
    if (fabs(f_left) < fabs(f_right)) {
        swap_double(&left, &right);
        swap_double(&f_left, &f_right);
    }

    double c = left;
    double f_c = f_left;
    double d = right - left;
    for (int iteration = 0; iteration < 100; iteration++) {
        if (f_right == 0.0) return right;
        double candidate;
        if (f_c != f_left && f_c != f_right) {
            candidate = left * f_right * f_c / ((f_left - f_right) * (f_left - f_c)) +
                        right * f_left * f_c / ((f_right - f_left) * (f_right - f_c)) +
                        c * f_left * f_right / ((f_c - f_left) * (f_c - f_right));
        } else {
            candidate = right - f_right * (right - left) / (f_right - f_left);
        }

        double quarter = (3.0 * left + right) / 4.0;
        bool outside = right > left ? !(quarter < candidate && candidate < right)
                                    : !(right < candidate && candidate < quarter);
        bool use_bisection = outside ||
            (iteration > 1 && fabs(candidate - right) >= fabs(right - c) / 2.0) ||
            (iteration <= 1 && fabs(candidate - right) >= fabs(c - d) / 2.0) ||
            (iteration > 1 && fabs(right - c) < TOLERANCE) ||
            (iteration <= 1 && fabs(c - d) < TOLERANCE);
        if (use_bisection) {
            candidate = (left + right) / 2.0;
            d = right - left;
        }

        double f_candidate = function_value(function_id, candidate);
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
        if (fabs(f_left) < fabs(f_right)) {
            swap_double(&left, &right);
            swap_double(&f_left, &f_right);
        }
        if (fabs(right - left) < TOLERANCE) return right;
    }
    return right;
}
