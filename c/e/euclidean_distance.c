#include <math.h>
#include <stddef.h>
#include <stdint.h>
#define MAX_DIMENSION 128
#define INVALID_RESULT (-1.0e300)

double euclidean_distance(const int64_t *values, size_t length) {
    if (values == NULL || length < 1) return INVALID_RESULT;
    const int64_t dimension = values[0];
    if (dimension < 0 || dimension > MAX_DIMENSION || length != 1 + 2 * (size_t)dimension)
        return INVALID_RESULT;
    double sum_of_squares = 0.0;
    for (size_t i = 0; i < (size_t)dimension; ++i) {
        const int64_t first = values[1 + i];
        const int64_t second = values[1 + (size_t)dimension + i];
        if (first < -1000000 || first > 1000000 || second < -1000000 || second > 1000000)
            return INVALID_RESULT;
        const double difference = (double)first - (double)second;
        sum_of_squares += difference * difference;
    }
    return sqrt(sum_of_squares);
}
