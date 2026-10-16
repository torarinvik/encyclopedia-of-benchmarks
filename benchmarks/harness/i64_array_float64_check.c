/* Batch checker for binary64 functions that consume a read-only i64 array. */
#include <float.h>
#include <inttypes.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#ifndef BENCHMARK_FUNCTION
#error "Compile with -DBENCHMARK_FUNCTION=<exported function symbol>"
#endif

#define MAX_INPUT_LENGTH 4096
extern double BENCHMARK_FUNCTION(const int64_t *values, size_t length);

_Static_assert(sizeof(double) == sizeof(uint64_t) && DBL_MANT_DIG == 53 && DBL_MAX_EXP == 1024,
               "i64_array_float64 requires IEEE 754 binary64 double");

static int matches(double observed, double expected, double relative_tolerance,
                   double absolute_tolerance)
{
    if (!isfinite(observed)) return 0;
    return fabs(observed - expected) <= absolute_tolerance + relative_tolerance * fabs(expected);
}

int main(void)
{
    uint64_t case_count, checked = 0;
    if (scanf("%" SCNu64, &case_count) != 1 || case_count == 0 || case_count > 1000000) {
        fprintf(stderr, "expected a nonempty case count\n");
        return 2;
    }
    while (checked < case_count) {
        uint64_t length_arg, null_pointer_arg;
        double expected, relative_tolerance, absolute_tolerance;
        if (scanf("%" SCNu64 " %" SCNu64 " %lf %lf %lf", &length_arg,
                  &null_pointer_arg, &expected, &relative_tolerance,
                  &absolute_tolerance) != 5 || length_arg > MAX_INPUT_LENGTH ||
            null_pointer_arg > 1 || !isfinite(expected) ||
            !isfinite(relative_tolerance) || relative_tolerance < 0.0 ||
            !isfinite(absolute_tolerance) || absolute_tolerance < 0.0) {
            fprintf(stderr, "invalid array-float64 case header\n");
            return 2;
        }
        const size_t length = (size_t)length_arg;
        int64_t *allocated_values = length == 0 || null_pointer_arg != 0
            ? NULL : malloc(length * sizeof(*allocated_values));
        const int64_t *values = null_pointer_arg != 0 ? NULL : allocated_values;
        if (length != 0 && null_pointer_arg == 0 && allocated_values == NULL) {
            fprintf(stderr, "unable to allocate checker input\n");
            return 2;
        }
        for (size_t index = 0; null_pointer_arg == 0 && index < length; ++index) {
            if (scanf("%" SCNd64, &allocated_values[index]) != 1) {
                free(allocated_values);
                fprintf(stderr, "truncated array input\n");
                return 2;
            }
        }
        const double observed = BENCHMARK_FUNCTION(values, length);
        free(allocated_values);
        if (!matches(observed, expected, relative_tolerance, absolute_tolerance)) {
            fprintf(stderr, "case=%" PRIu64 ": expected %.17g, observed %.17g\n",
                    checked, expected, observed);
            return 3;
        }
        ++checked;
    }
    char extra[2];
    if (scanf("%1s", extra) == 1 || ferror(stdin)) {
        fprintf(stderr, "unexpected trailing checker input\n");
        return 2;
    }
    printf("{\"cases_checked\":%" PRIu64 "}\n", checked);
    return 0;
}
