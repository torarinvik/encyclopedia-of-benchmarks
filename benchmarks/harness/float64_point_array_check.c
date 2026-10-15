/* Batch checker for a binary64 point-array function returning one scalar. */
#include <errno.h>
#include <inttypes.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#ifndef BENCHMARK_FUNCTION
#error "Compile with -DBENCHMARK_FUNCTION=<exported function symbol>"
#endif

extern double BENCHMARK_FUNCTION(const double *points, size_t point_count);

#define MAX_POINT_COUNT 65536

static int read_number(double *value)
{
    char token[128];
    char *end = NULL;
    if (scanf("%127s", token) != 1) return 0;
    errno = 0;
    *value = strtod(token, &end);
    return errno != ERANGE && end != token && *end == '\0';
}

static int matches(double observed, double expected, double relative_tolerance)
{
    if (isnan(expected)) return isnan(observed);
    return isfinite(observed) &&
        fabs(observed - expected) <= relative_tolerance * fabs(expected);
}

int main(void)
{
    uint64_t case_count, checked = 0;
    if (scanf("%" SCNu64, &case_count) != 1 || case_count == 0 || case_count > 1000000) {
        fprintf(stderr, "expected a nonempty case count\n");
        return 2;
    }
    while (checked < case_count) {
        uint64_t point_count_arg;
        double expected, relative_tolerance;
        if (scanf("%" SCNu64, &point_count_arg) != 1 || point_count_arg > MAX_POINT_COUNT ||
            !read_number(&expected) || (!isfinite(expected) && !isnan(expected)) ||
            !read_number(&relative_tolerance) || !isfinite(relative_tolerance) ||
            relative_tolerance <= 0.0) {
            fprintf(stderr, "invalid point-array case header\n");
            return 2;
        }
        const size_t point_count = (size_t)point_count_arg;
        double *points = point_count == 0 ? NULL : malloc(2 * point_count * sizeof(*points));
        if (point_count != 0 && points == NULL) {
            fprintf(stderr, "unable to allocate point input\n");
            return 2;
        }
        for (size_t index = 0; index < 2 * point_count; ++index) {
            if (!read_number(&points[index]) || !isfinite(points[index]) ||
                points[index] < 0.0 || points[index] > 1.0) {
                fprintf(stderr, "point coordinates must be finite values in [0, 1]\n");
                free(points);
                return 2;
            }
        }
        const double observed = BENCHMARK_FUNCTION(points, point_count);
        if (!matches(observed, expected, relative_tolerance)) {
            fprintf(stderr, "case=%" PRIu64 ": expected %.17g, observed %.17g\n",
                    checked, expected, observed);
            free(points);
            return 3;
        }
        free(points);
        ++checked;
    }
    char extra[2];
    if (scanf("%1s", extra) == 1 || ferror(stdin)) {
        fprintf(stderr, "unexpected trailing input\n");
        return 2;
    }
    printf("{\"cases_checked\":%" PRIu64 "}\n", checked);
    return 0;
}
