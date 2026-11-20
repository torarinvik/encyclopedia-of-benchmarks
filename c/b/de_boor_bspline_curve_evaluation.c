#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 24
#define MAX_DEGREE 3
#define MAX_CONTROLS 8

static int exact_integer(double value, int low, int high, int *decoded) {
    if (!isfinite(value) || value < (double)low || value > (double)high || trunc(value) != value) return 0;
    *decoded = (int)value;
    return 1;
}

static int parse(const double *input, size_t length, int *degree, int *count,
                 double *parameter, const double **knots, const double **controls) {
    if (length < 3 || length > MAX_INPUT_LENGTH) return 0;
    if (!exact_integer(input[0], 1, MAX_DEGREE, degree) ||
        !exact_integer(input[1], *degree + 1, MAX_CONTROLS, count) || !isfinite(input[2])) return 0;
    size_t knot_count = (size_t)(*count + *degree + 1);
    if (length != 3 + knot_count + (size_t)*count) return 0;
    *parameter = input[2];
    *knots = input + 3;
    *controls = input + 3 + knot_count;
    for (size_t i = 0; i < knot_count; ++i) {
        if (!isfinite((*knots)[i]) || (*knots)[i] < -1000.0 || (*knots)[i] > 1000.0) return 0;
        if (i && (*knots)[i] < (*knots)[i - 1]) return 0;
    }
    for (int i = 0; i < *count; ++i)
        if (!isfinite((*controls)[i]) || (*controls)[i] < -1000.0 || (*controls)[i] > 1000.0) return 0;
    int run = 1;
    for (size_t i = 1; i < knot_count; ++i) {
        run = ((*knots)[i] == (*knots)[i - 1]) ? run + 1 : 1;
        if (run > *degree + 1) return 0;
    }
    double lower = (*knots)[*degree], upper = (*knots)[*count];
    return lower < upper && lower <= *parameter && *parameter <= upper;
}

static double evaluate(int degree, int count, double u, const double *knots,
                       const double *controls) {
    int span = count - 1;
    if (u != knots[count]) {
        span = degree;
        while (span < count - 1 && u >= knots[span + 1]) ++span;
    }
    double local[4];
    for (int j = 0; j <= degree; ++j) local[j] = controls[span - degree + j];
    for (int level = 1; level <= degree; ++level) {
        for (int slot = degree; slot >= level; --slot) {
            int left = span - degree + slot;
            int right = span + slot - level + 1;
            double denominator = knots[right] - knots[left];
            double alpha = denominator == 0.0 ? 0.0 : (u - knots[left]) / denominator;
            local[slot] = (1.0 - alpha) * local[slot - 1] + alpha * local[slot];
        }
    }
    return local[degree];
}

int64_t de_boor_bspline_curve_evaluation(const double *input, size_t input_length,
                                         double *output, size_t output_capacity) {
    if (input == NULL) return -1;
    int degree, count;
    double parameter;
    const double *knots, *controls;
    if (!parse(input, input_length, &degree, &count, &parameter, &knots, &controls)) return -1;
    if (output == NULL || output_capacity < 1) return -2;
    double result = evaluate(degree, count, parameter, knots, controls);
    if (!isfinite(result)) return -1;
    output[0] = result;
    return 1;
}
