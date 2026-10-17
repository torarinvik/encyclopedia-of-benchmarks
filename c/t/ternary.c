#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH ((size_t)6)
#define INVALID_RESULT (-1.0e300)

static double objective(int64_t operation, double x) {
    const double delta = operation == 0 ? x - 1.0 : x + 1.0;
    const double square = delta * delta;
    return operation == 0 ? -square : square;
}

static double ternary_search(int64_t operation, double a, double b, double epsilon,
                             int64_t frame, int64_t max_calls) {
    if (fabs(a - b) <= epsilon) return objective(operation, (a + b) / 2.0);

    const double left = (2.0 * a + b) / 3.0;
    const double right = (a + 2.0 * b) / 3.0;
    const double left_value = objective(operation, left);
    const double right_value = objective(operation, right);
    const int take_left = operation == 0 ? left_value < right_value : left_value > right_value;
    if (frame >= max_calls) return INVALID_RESULT;
    if (take_left) return ternary_search(operation, left, b, epsilon, frame + 1, max_calls);
    return ternary_search(operation, a, right, epsilon, frame + 1, max_calls);
}

double ternary(const int64_t *input, size_t length) {
    if (input == NULL || length < 5 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const int64_t operation = input[0];
    const int64_t a_milli = input[1];
    const int64_t b_milli = input[2];
    const int64_t epsilon_micro = input[3];
    const int64_t max_calls = input[4];
    if (length != 5 || (operation != 0 && operation != 1) ||
        a_milli < -1000000 || a_milli > b_milli || b_milli > 1000000 ||
        epsilon_micro < 1 || epsilon_micro > 1000000 || max_calls < 1 || max_calls > 64)
        return INVALID_RESULT;

    return ternary_search(operation, (double)a_milli / 1000.0, (double)b_milli / 1000.0,
                          (double)epsilon_micro / 1000000.0, 1, max_calls);
}
