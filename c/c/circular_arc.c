#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)
double circular_arc(const int64_t *input, size_t length) {
    if (input == NULL || length != 3) return INVALID_RESULT;
    const int64_t mode = input[0], radius = input[1], degrees = input[2];
    if ((mode != 0 && mode != 1) || radius < -1000000 || radius > 1000000 || degrees < -360000 || degrees > 360000) return INVALID_RESULT;
    const double angle = (double)degrees * (3.14159265358979323846 / 180.0);
    if (mode == 0) return (double)radius * angle;
    return ((double)(radius * radius) * angle) / 2.0;
}
