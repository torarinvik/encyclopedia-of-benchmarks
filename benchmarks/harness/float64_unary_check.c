/* Batch checker for a one-input binary64 function. */
#include <inttypes.h>
#include <float.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>

#ifndef BENCHMARK_FUNCTION
#error "Compile with -DBENCHMARK_FUNCTION=<exported function symbol>"
#endif

extern double BENCHMARK_FUNCTION(double input);

_Static_assert(sizeof(double) == sizeof(uint64_t) && DBL_MANT_DIG == 53 && DBL_MAX_EXP == 1024,
               "float64_unary requires IEEE 754 binary64 double");

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
        double input, expected, relative_tolerance, absolute_tolerance;
        if (scanf("%lf %lf %lf %lf", &input, &expected, &relative_tolerance,
                  &absolute_tolerance) != 4 ||
            !isfinite(input) || !isfinite(expected) ||
            !isfinite(relative_tolerance) || relative_tolerance <= 0.0 ||
            !isfinite(absolute_tolerance) || absolute_tolerance < 0.0) {
            fprintf(stderr, "invalid one-input binary64 case\n");
            return 2;
        }
        const double observed = BENCHMARK_FUNCTION(input);
        if (!matches(observed, expected, relative_tolerance, absolute_tolerance)) {
            fprintf(stderr, "case=%" PRIu64 ": expected %.17g, observed %.17g\n",
                    checked, expected, observed);
            return 3;
        }
        ++checked;
    }
    printf("{\"cases_checked\":%" PRIu64 "}\n", checked);
    return 0;
}
