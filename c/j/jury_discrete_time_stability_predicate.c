#include <stddef.h>
#include <stdint.h>

#define JURY_MAX_DEGREE INT64_C(4)
#define JURY_MAX_PARSEABLE_LENGTH ((size_t)7)

int64_t jury_discrete_time_stability_predicate(const int64_t *input, size_t length) {
    if (input == NULL || length < 1U || length > JURY_MAX_PARSEABLE_LENGTH) return -1;
    const int64_t degree = input[0];
    if (degree < 1 || degree > JURY_MAX_DEGREE || length != (size_t)degree + 2U) return -1;

    int64_t coefficients[5] = {0, 0, 0, 0, 0};
    for (int64_t index = 0; index <= degree; ++index) {
        const int64_t value = input[(size_t)index + 1U];
        if (value < -9 || value > 9 || (index == 0 && value == 0)) return -1;
        coefficients[index] = value;
    }
    if (coefficients[0] < 0) {
        for (int64_t index = 0; index <= degree; ++index) coefficients[index] = -coefficients[index];
    }

    int64_t at_one = 0;
    int64_t at_minus_one = 0;
    for (int64_t index = 0; index <= degree; ++index) {
        at_one += coefficients[index];
        at_minus_one += ((degree - index) % 2 == 0) ? coefficients[index] : -coefficients[index];
    }
    if (at_one <= 0 || ((degree % 2 == 0) ? at_minus_one <= 0 : at_minus_one >= 0)) return 0;

    int64_t row[5] = {0, 0, 0, 0, 0};
    int64_t reduced[5] = {0, 0, 0, 0, 0};
    for (int64_t index = 0; index <= degree; ++index) row[index] = coefficients[index];
    for (int64_t current_degree = degree; current_degree >= 1; --current_degree) {
        const int64_t trailing = row[current_degree];
        const int64_t trailing_magnitude = trailing < 0 ? -trailing : trailing;
        if (row[0] <= trailing_magnitude) return 0;
        if (current_degree == 1) break;
        for (int64_t index = 0; index < current_degree; ++index) {
            reduced[index] = row[0] * row[index] - trailing * row[current_degree - index];
        }
        for (int64_t index = 0; index < current_degree; ++index) row[index] = reduced[index];
    }
    return 1;
}
