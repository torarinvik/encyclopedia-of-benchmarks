/* Batch checker for a two-input binary64 function. */
#include <inttypes.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>

#ifndef BENCHMARK_FUNCTION
#error "Compile with -DBENCHMARK_FUNCTION=<exported function symbol>"
#endif

extern double BENCHMARK_FUNCTION(double first, double second);

int main(void)
{
    uint64_t case_count, checked = 0;
    if (scanf("%" SCNu64, &case_count) != 1 || case_count == 0 || case_count > 1000000) {
        fprintf(stderr, "expected a nonempty case count\n");
        return 2;
    }
    while (checked < case_count) {
        double first, second, expected, relative_tolerance;
        if (scanf("%lf %lf %lf %lf", &first, &second, &expected, &relative_tolerance) != 4 ||
            !isfinite(first) || !isfinite(second) || !isfinite(expected) ||
            !isfinite(relative_tolerance) || relative_tolerance <= 0.0) {
            fprintf(stderr, "invalid binary64 pair case\n");
            return 2;
        }
        const double observed = BENCHMARK_FUNCTION(first, second);
        const double scale = fmax(1.0, fmax(fabs(first), fabs(second)));
        if (!isfinite(observed) || fabs(observed - expected) > relative_tolerance * scale) {
            fprintf(stderr, "case=%" PRIu64 ": expected %.17g, observed %.17g\n",
                    checked, expected, observed);
            return 3;
        }
        ++checked;
    }
    printf("{\"cases_checked\":%" PRIu64 "}\n", checked);
    return 0;
}
