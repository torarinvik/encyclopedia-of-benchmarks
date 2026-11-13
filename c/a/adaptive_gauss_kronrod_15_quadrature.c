#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_INTERVALS 16
#define MAX_INPUT_LENGTH 6
#define INVALID_RESULT INT64_C(-1)
#define OUTPUT_ERROR INT64_C(-2)
#define NUMERICAL_FAILURE INT64_C(-3)

typedef struct {
    double a;
    double b;
    double value;
    double error;
} interval_t;

static const double nodes[7] = {
    0.991455371120812639206854697526329,
    0.949107912342758524526189684047851,
    0.864864423359769072789712788640926,
    0.741531185599394439863864773280788,
    0.586087235467691130294144838258730,
    0.405845151377397166906606412076961,
    0.207784955007898467600689403773245
};
static const double kronrod_weights[7] = {
    0.022935322010529224963732008058970,
    0.063092092629978553290700663189204,
    0.104790010322250183839876322541518,
    0.140653259715525918745189590510238,
    0.169004726639267902826583426598550,
    0.190350578064785409913256402421014,
    0.204432940075298892414161999234649
};
static const double gauss_weights[3] = {
    0.129484966168869693270611432679082,
    0.279705391489276667901467771423780,
    0.381830050505118944950369775488975
};

static int integer_field(double x, int low, int high, int *value)
{
    if (!isfinite(x) || x < (double)low || x > (double)high || trunc(x) != x) return 0;
    *value = (int)x;
    return 1;
}

static double sample(int function_id, double x)
{
    if (function_id == 0) return exp(4.0 * x);
    if (function_id == 1) return sin(10.0 * x);
    if (function_id == 2) return 1.0 / (1.0 + 9.0 * x * x);
    double x2 = x * x;
    double x4 = x2 * x2;
    double x8 = x4 * x4;
    return x8 * x4 * x2;
}

static void pair_estimate(int function_id, double a, double b,
                          double *kronrod_result, double *gauss_result)
{
    const double center = (a + b) * 0.5;
    const double half = (b - a) * 0.5;
    const double center_value = sample(function_id, center);
    double kronrod = 0.209482141084727828012999174891714 * center_value;
    double gauss = 0.417959183673469387755102040816327 * center_value;
    for (int i = 0; i < 7; ++i) {
        const double offset = half * nodes[i];
        const double pair = sample(function_id, center - offset) + sample(function_id, center + offset);
        kronrod += kronrod_weights[i] * pair;
        if (i == 1) gauss += gauss_weights[0] * pair;
        if (i == 3) gauss += gauss_weights[1] * pair;
        if (i == 5) gauss += gauss_weights[2] * pair;
    }
    *kronrod_result = half * kronrod;
    *gauss_result = half * gauss;
}

int64_t adaptive_gauss_kronrod_15_quadrature(const double *input, size_t input_length,
                                             double *output, size_t output_capacity)
{
    if (input == NULL || input_length != 5 || input_length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    int function_id, a_micro, b_micro, exponent, limit;
    if (!integer_field(input[0], 0, 3, &function_id) ||
        !integer_field(input[1], -1000000, 1000000, &a_micro) ||
        !integer_field(input[2], -1000000, 1000000, &b_micro) ||
        !integer_field(input[3], 6, 8, &exponent) ||
        !integer_field(input[4], 1, MAX_INTERVALS, &limit) || a_micro > b_micro)
        return INVALID_RESULT;
    if (output == NULL || output_capacity < 1) return OUTPUT_ERROR;

    const double a = (double)a_micro / 1000000.0;
    const double b = (double)b_micro / 1000000.0;
    if (a == b) {
        output[0] = 0.0;
        return 1;
    }
    interval_t intervals[MAX_INTERVALS];
    double k, g;
    pair_estimate(function_id, a, b, &k, &g);
    intervals[0] = (interval_t){a, b, k, fabs(k - g)};
    int count = 1;
    double tolerance = 1.0;
    for (int i = 0; i < exponent; ++i) tolerance *= 0.1;
    for (;;) {
        double total = 0.0, error = 0.0;
        for (int i = 0; i < count; ++i) {
            total += intervals[i].value;
            error += intervals[i].error;
        }
        if (error <= tolerance * fmax(1.0, fabs(total))) {
            if (!isfinite(total)) return INVALID_RESULT;
            output[0] = total;
            return 1;
        }
        if (count >= limit) return NUMERICAL_FAILURE;
        int best = 0;
        for (int i = 1; i < count; ++i) {
            if (intervals[i].error > intervals[best].error ||
                (intervals[i].error == intervals[best].error && intervals[i].a < intervals[best].a))
                best = i;
        }
        const double left = intervals[best].a;
        const double right = intervals[best].b;
        const double middle = (left + right) * 0.5;
        double lk, lg, rk, rg;
        pair_estimate(function_id, left, middle, &lk, &lg);
        pair_estimate(function_id, middle, right, &rk, &rg);
        intervals[best] = (interval_t){left, middle, lk, fabs(lk - lg)};
        intervals[count++] = (interval_t){middle, right, rk, fabs(rk - rg)};
    }
}
