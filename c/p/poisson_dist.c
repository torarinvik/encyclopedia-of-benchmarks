#include <math.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_MILLI_VALUE = 100000, MAX_SUCCESS_COUNT = 20 };
#define INVALID_RESULT (-1.0e300)

static double poisson_factorial(double x)
{
    double factorial = x;
    for (int64_t i = (int64_t)x - 1; i > 0; --i) factorial *= (double)i;
    if (factorial <= 0.0) factorial = 1.0;
    return factorial;
}

static double poisson_point(double mean, int64_t successes)
{
    return (pow(mean, (double)successes) * exp(-mean)) / poisson_factorial((double)successes);
}

double poisson_dist(const int64_t *input, size_t length)
{
    if (input == NULL || length != 4) return INVALID_RESULT;
    const int64_t operation = input[0];
    const int64_t first = input[1];
    const int64_t second = input[2];
    const int64_t third = input[3];

    if (operation == 0) {
        if (first < 0 || first > MAX_MILLI_VALUE || second < 1 || second > MAX_MILLI_VALUE || third != 0)
            return INVALID_RESULT;
        return ((double)first / 1000.0) / ((double)second / 1000.0);
    }
    if (operation == 1) {
        if (first < 0 || first > MAX_MILLI_VALUE || second < 0 || second > MAX_MILLI_VALUE || third != 0)
            return INVALID_RESULT;
        return ((double)first / 1000.0) * ((double)second / 1000.0);
    }
    if (operation == 2) {
        if (first < 0 || first > MAX_MILLI_VALUE || second < 0 || second > MAX_SUCCESS_COUNT || third != 0)
            return INVALID_RESULT;
        return poisson_point((double)first / 1000.0, second);
    }
    if (operation == 3) {
        if (first < 0 || first > MAX_MILLI_VALUE || second < 0 || second > third || third > MAX_SUCCESS_COUNT)
            return INVALID_RESULT;
        const double mean = (double)first / 1000.0;
        double probability = 0.0;
        for (int64_t successes = second; successes <= third; ++successes)
            probability += poisson_point(mean, successes);
        return probability;
    }
    return INVALID_RESULT;
}
