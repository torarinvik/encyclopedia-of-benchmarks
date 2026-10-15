/* Timed runner for a binary64 scalar function over a read-only i64 array. */
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

#define MAX_INPUT_LENGTH 4096
typedef double (*array_fn)(const int64_t *, size_t);
extern double BENCHMARK_FUNCTION(const int64_t *values, size_t length);
static array_fn volatile run_algorithm = BENCHMARK_FUNCTION;

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

static int parse_i64(const char *text, int64_t *value)
{
    char *end = NULL;
    long long parsed;
    if (text[0] == '\0') return 0;
    errno = 0;
    parsed = strtoll(text, &end, 10);
    if (errno == ERANGE || end == text || *end != '\0') return 0;
    *value = (int64_t)parsed;
    return 1;
}

static int parse_f64(const char *text, double *value)
{
    char *end = NULL;
    errno = 0;
    *value = strtod(text, &end);
    return end != text && *end == '\0' && isfinite(*value);
}

static uint64_t result_bits(double result)
{
    uint64_t bits;
    memcpy(&bits, &result, sizeof(bits));
    return bits;
}

/* Match using abs(actual-expected) <= abs_tol + rel_tol*abs(expected). */
static int result_matches(double actual, double expected, double absolute_tolerance,
                          double relative_tolerance)
{
    if (!isfinite(actual)) return 0;
    return fabs(actual - expected) <= absolute_tolerance + relative_tolerance * fabs(expected);
}

static double run_batch(const int64_t *values, size_t length, size_t repetitions,
                        uint64_t *checksum)
{
    double result = 0.0;
    uint64_t local_checksum = 0;
    for (size_t repetition = 0; repetition < repetitions; ++repetition) {
        result = run_algorithm(values, length);
        local_checksum += result_bits(result);
    }
    *checksum = local_checksum;
    return result;
}

int main(int argc, char **argv)
{
    uint64_t length_arg, samples_arg, warmups_arg, repetitions_arg;
    const int stdin_mode = argc > 1 && strcmp(argv[1], "--stdin") == 0;
    if (stdin_mode) {
        if (argc != 9 || !parse_u64(argv[2], &length_arg) || length_arg > MAX_INPUT_LENGTH) {
            fprintf(stderr, "usage: i64_array_float64_runner --stdin LENGTH EXPECTED ABS_TOL REL_TOL SAMPLES WARMUPS REPETITIONS\n");
            return 2;
        }
    } else if (argc < 8 || !parse_u64(argv[1], &length_arg) || length_arg > MAX_INPUT_LENGTH ||
               (uint64_t)argc != length_arg + 8) {
        fprintf(stderr, "usage: i64_array_float64_runner LENGTH VALUES... EXPECTED ABS_TOL REL_TOL SAMPLES WARMUPS REPETITIONS\n");
        return 2;
    }

    const size_t length = (size_t)length_arg;
    int64_t *values = length == 0 ? NULL : malloc(length * sizeof(*values));
    if (length != 0 && values == NULL) {
        fprintf(stderr, "unable to allocate input values\n");
        return 2;
    }
    for (size_t index = 0; index < length; ++index) {
        const int parsed = stdin_mode
            ? scanf("%" SCNd64, &values[index]) == 1
            : parse_i64(argv[index + 2], &values[index]);
        if (!parsed) {
            fprintf(stderr, "invalid signed 64-bit array value\n");
            free(values);
            return 2;
        }
    }
    if (stdin_mode) {
        char extra[2];
        if (scanf("%1s", extra) == 1 || ferror(stdin)) {
            fprintf(stderr, "unexpected trailing streamed input\n");
            free(values);
            return 2;
        }
    }

    const size_t expected_index = stdin_mode ? 3 : length + 2;
    double expected, absolute_tolerance, relative_tolerance;
    if (!parse_f64(argv[expected_index], &expected) ||
        !parse_f64(argv[expected_index + 1], &absolute_tolerance) || absolute_tolerance < 0.0 ||
        !parse_f64(argv[expected_index + 2], &relative_tolerance) || relative_tolerance < 0.0 ||
        !parse_u64(argv[expected_index + 3], &samples_arg) ||
        !parse_u64(argv[expected_index + 4], &warmups_arg) ||
        !parse_u64(argv[expected_index + 5], &repetitions_arg) ||
        samples_arg == 0 || samples_arg > 10000 || warmups_arg > 100000 ||
        repetitions_arg == 0 || repetitions_arg > 1000000000) {
        fprintf(stderr, "invalid expected value or timing settings\n");
        free(values);
        return 2;
    }

    const size_t sample_count = (size_t)samples_arg;
    const size_t warmup_count = (size_t)warmups_arg;
    const size_t repetitions = (size_t)repetitions_arg;
    uint64_t *sample_ns = malloc(sample_count * sizeof(*sample_ns));
    if (sample_ns == NULL) {
        fprintf(stderr, "unable to allocate sample data\n");
        free(values);
        return 2;
    }
    if (!result_matches(run_algorithm(values, length), expected, absolute_tolerance, relative_tolerance)) {
        fprintf(stderr, "correctness mismatch for array input\n");
        free(sample_ns);
        free(values);
        return 3;
    }

    volatile uint64_t warmup_observer = 0;
    for (size_t warmup = 0; warmup < warmup_count; ++warmup) {
        uint64_t checksum = 0;
        if (!result_matches(run_batch(values, length, repetitions, &checksum), expected,
                            absolute_tolerance, relative_tolerance)) {
            fprintf(stderr, "algorithm result changed during warmup\n");
            free(sample_ns);
            free(values);
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
            free(values);
            return 4;
        }
        uint64_t checksum = 0;
        observed_result = run_batch(values, length, repetitions, &checksum);
        const clock_t finish = clock();
        if (finish == (clock_t)-1 || finish < start ||
            !result_matches(observed_result, expected, absolute_tolerance, relative_tolerance)) {
            fprintf(stderr, "clock() or result check failed during a sample\n");
            free(sample_ns);
            free(values);
            return 4;
        }
        total_checksum += checksum;
        const long double elapsed_ns =
            ((long double)(finish - start) * 1000000000.0L) / (long double)CLOCKS_PER_SEC;
        sample_ns[sample] = (uint64_t)(elapsed_ns + 0.5L);
    }

    printf("{\"observed_result\":%.17g,\"samples_ns\":[", observed_result);
    for (size_t sample = 0; sample < sample_count; ++sample)
        printf("%s%" PRIu64, sample == 0 ? "" : ",", sample_ns[sample]);
    printf("],\"result_checksum\":%" PRIu64 ",\"timer_resolution_ns\":%.3Lf}\n",
           total_checksum, 1000000000.0L / (long double)CLOCKS_PER_SEC);
    (void)warmup_observer;
    free(sample_ns);
    free(values);
    return 0;
}
