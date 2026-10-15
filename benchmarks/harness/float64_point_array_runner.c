/* Timed runner for a binary64 point-array function returning one scalar. */
#include <errno.h>
#include <inttypes.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#ifndef BENCHMARK_FUNCTION
#error "Compile with -DBENCHMARK_FUNCTION=<exported function symbol>"
#endif

typedef double (*point_array_fn)(const double *, size_t);
extern double BENCHMARK_FUNCTION(const double *points, size_t point_count);
static point_array_fn volatile run_algorithm = BENCHMARK_FUNCTION;

#define MAX_POINT_COUNT 65536

static int parse_u64(const char *text, uint64_t *value)
{
    char *end = NULL;
    unsigned long long parsed;
    if (text[0] == '-' || text[0] == '\0') return 0;
    errno = 0;
    parsed = strtoull(text, &end, 10);
    if (errno == ERANGE || end == text || *end != '\0') return 0;
    *value = (uint64_t)parsed;
    return 1;
}

static int parse_f64(const char *text, double *value)
{
    char *end = NULL;
    errno = 0;
    *value = strtod(text, &end);
    return errno != ERANGE && end != text && *end == '\0';
}

static int matches(double observed, double expected, double relative_tolerance)
{
    if (isnan(expected)) return isnan(observed);
    return isfinite(observed) &&
        fabs(observed - expected) <= relative_tolerance * fabs(expected);
}

static double run_batch(const double *points, size_t point_count, size_t repetitions,
                        uint64_t *checksum)
{
    double result = 0.0;
    uint64_t local_checksum = 0;
    for (size_t repetition = 0; repetition < repetitions; ++repetition) {
        result = run_algorithm(points, point_count);
        uint64_t bits;
        memcpy(&bits, &result, sizeof(bits));
        local_checksum += bits;
    }
    *checksum = local_checksum;
    return result;
}

int main(int argc, char **argv)
{
    uint64_t point_count_arg, samples_arg, warmups_arg, repetitions_arg;
    double expected, relative_tolerance;
    if (argc != 8 || strcmp(argv[1], "--stdin") != 0 ||
        !parse_u64(argv[2], &point_count_arg) || point_count_arg > MAX_POINT_COUNT ||
        !parse_f64(argv[3], &expected) || (!isfinite(expected) && !isnan(expected)) ||
        !parse_f64(argv[4], &relative_tolerance) || !isfinite(relative_tolerance) ||
        relative_tolerance <= 0.0 || !parse_u64(argv[5], &samples_arg) ||
        !parse_u64(argv[6], &warmups_arg) || !parse_u64(argv[7], &repetitions_arg) ||
        samples_arg == 0 || samples_arg > 10000 || warmups_arg > 100000 ||
        repetitions_arg == 0 || repetitions_arg > 1000000000) {
        fprintf(stderr, "usage: float64_point_array_runner --stdin POINT_COUNT EXPECTED REL_TOL SAMPLES WARMUPS REPETITIONS\n");
        return 2;
    }

    const size_t point_count = (size_t)point_count_arg;
    const size_t sample_count = (size_t)samples_arg;
    const size_t warmup_count = (size_t)warmups_arg;
    const size_t repetitions = (size_t)repetitions_arg;
    double *points = point_count == 0 ? NULL : malloc(2 * point_count * sizeof(*points));
    uint64_t *sample_ns = malloc(sample_count * sizeof(*sample_ns));
    if ((point_count != 0 && points == NULL) || sample_ns == NULL) {
        fprintf(stderr, "unable to allocate runner input or sample data\n");
        free(sample_ns);
        free(points);
        return 2;
    }
    for (size_t index = 0; index < 2 * point_count; ++index) {
        if (scanf("%lf", &points[index]) != 1 || !isfinite(points[index]) ||
            points[index] < 0.0 || points[index] > 1.0) {
            fprintf(stderr, "point coordinates must be finite values in [0, 1]\n");
            free(sample_ns);
            free(points);
            return 2;
        }
    }
    char extra[2];
    if (scanf("%1s", extra) == 1 || ferror(stdin)) {
        fprintf(stderr, "unexpected trailing input\n");
        free(sample_ns);
        free(points);
        return 2;
    }
    if (!matches(run_algorithm(points, point_count), expected, relative_tolerance)) {
        fprintf(stderr, "correctness mismatch for point-array input\n");
        free(sample_ns);
        free(points);
        return 3;
    }
    volatile uint64_t warmup_observer = 0;
    for (size_t warmup = 0; warmup < warmup_count; ++warmup) {
        uint64_t checksum = 0;
        if (!matches(run_batch(points, point_count, repetitions, &checksum), expected,
                     relative_tolerance)) {
            fprintf(stderr, "algorithm result changed during warmup\n");
            free(sample_ns);
            free(points);
            return 3;
        }
        warmup_observer ^= checksum;
    }

    uint64_t total_checksum = 0;
    double observed_result = expected;
    for (size_t sample = 0; sample < sample_count; ++sample) {
        const clock_t start = clock();
        if (start == (clock_t)-1) {
            fprintf(stderr, "clock() failed before a sample\n");
            free(sample_ns);
            free(points);
            return 4;
        }
        uint64_t checksum = 0;
        observed_result = run_batch(points, point_count, repetitions, &checksum);
        const clock_t finish = clock();
        if (finish == (clock_t)-1 || finish < start ||
            !matches(observed_result, expected, relative_tolerance)) {
            fprintf(stderr, "clock() or result check failed during a sample\n");
            free(sample_ns);
            free(points);
            return 4;
        }
        total_checksum += checksum;
        const long double elapsed_ns =
            ((long double)(finish - start) * 1000000000.0L) / (long double)CLOCKS_PER_SEC;
        sample_ns[sample] = (uint64_t)(elapsed_ns + 0.5L);
    }
    printf("{\"observed_result\":");
    if (isnan(observed_result)) printf("\"NaN\"");
    else printf("%.17g", observed_result);
    printf(",\"samples_ns\":[");
    for (size_t sample = 0; sample < sample_count; ++sample)
        printf("%s%" PRIu64, sample == 0 ? "" : ",", sample_ns[sample]);
    printf("],\"result_checksum\":%" PRIu64 ",\"timer_resolution_ns\":%.3Lf}\n",
           total_checksum, 1000000000.0L / (long double)CLOCKS_PER_SEC);
    (void)warmup_observer;
    free(sample_ns);
    free(points);
    return 0;
}
