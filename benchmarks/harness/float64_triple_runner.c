/* Timing runner for a three-input binary64 algorithm. */
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

typedef double (*lerp_fn)(double, double, double);
extern double BENCHMARK_FUNCTION(double start, double end, double t);
static lerp_fn volatile run_algorithm = BENCHMARK_FUNCTION;

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
    if (text[0] == '\0') return 0;
    errno = 0;
    *value = strtod(text, &end);
    return errno != ERANGE && end != text && *end == '\0' && isfinite(*value);
}

static int matches(double observed, double expected, double input_scaled_tolerance,
                   double start, double end)
{
    return isfinite(observed) &&
           fabs(observed - expected) <= input_scaled_tolerance *
               fmax(1.0, fmax(fabs(start), fabs(end)));
}

static uint64_t result_bits(double value)
{
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    return bits;
}

static double run_batch(double start, double end, double t, size_t repetitions, uint64_t *checksum)
{
    double result = 0.0;
    uint64_t local_checksum = 0;
    for (size_t repetition = 0; repetition < repetitions; ++repetition) {
        result = run_algorithm(start, end, t);
        local_checksum += result_bits(result);
    }
    *checksum = local_checksum;
    return result;
}

int main(int argc, char **argv)
{
    double start, end, t, expected, input_scaled_tolerance;
    uint64_t samples_arg, warmups_arg, repetitions_arg;
    if (argc != 9 || !parse_f64(argv[1], &start) || !parse_f64(argv[2], &end) ||
        !parse_f64(argv[3], &t) || !parse_f64(argv[4], &expected) ||
        !parse_f64(argv[5], &input_scaled_tolerance) ||
        input_scaled_tolerance < 0.0 || !parse_u64(argv[6], &samples_arg) ||
        !parse_u64(argv[7], &warmups_arg) || !parse_u64(argv[8], &repetitions_arg) ||
        samples_arg == 0 || samples_arg > 10000 || warmups_arg > 100000 ||
        repetitions_arg == 0 || repetitions_arg > 1000000000) {
        fprintf(stderr, "usage: float64_triple_runner START END T EXPECTED REL_TOL SAMPLES WARMUPS REPETITIONS\n");
        return 2;
    }
    const size_t sample_count = (size_t)samples_arg;
    const size_t warmup_count = (size_t)warmups_arg;
    const size_t repetitions = (size_t)repetitions_arg;
    uint64_t *sample_ns = malloc(sample_count * sizeof(*sample_ns));
    if (sample_ns == NULL) {
        fprintf(stderr, "unable to allocate sample data\n");
        return 2;
    }
    if (!matches(run_algorithm(start, end, t), expected, input_scaled_tolerance, start, end)) {
        fprintf(stderr, "correctness mismatch for float64 triple inputs\n");
        free(sample_ns);
        return 3;
    }
    volatile uint64_t warmup_observer = 0;
    for (size_t warmup = 0; warmup < warmup_count; ++warmup) {
        uint64_t checksum = 0;
        if (!matches(run_batch(start, end, t, repetitions, &checksum), expected,
                     input_scaled_tolerance, start, end)) {
            fprintf(stderr, "result changed during warmup\n");
            free(sample_ns);
            return 3;
        }
        warmup_observer ^= checksum;
    }
    uint64_t total_checksum = 0;
    double observed_result = expected;
    for (size_t sample = 0; sample < sample_count; ++sample) {
        const clock_t before = clock();
        if (before == (clock_t)-1) {
            fprintf(stderr, "clock() failed before a sample\n");
            free(sample_ns);
            return 4;
        }
        uint64_t checksum = 0;
        observed_result = run_batch(start, end, t, repetitions, &checksum);
        const clock_t after = clock();
        if (after == (clock_t)-1 || after < before ||
            !matches(observed_result, expected, input_scaled_tolerance, start, end)) {
            fprintf(stderr, "clock() or result check failed during a sample\n");
            free(sample_ns);
            return 4;
        }
        total_checksum += checksum;
        const long double elapsed_ns =
            ((long double)(after - before) * 1000000000.0L) / (long double)CLOCKS_PER_SEC;
        sample_ns[sample] = (uint64_t)(elapsed_ns + 0.5L);
    }
    printf("{\"observed_result\":%.17g,\"samples_ns\":[", observed_result);
    for (size_t sample = 0; sample < sample_count; ++sample)
        printf("%s%" PRIu64, sample == 0 ? "" : ",", sample_ns[sample]);
    printf("],\"result_checksum\":%" PRIu64 ",\"timer_resolution_ns\":%.3Lf}\n",
           total_checksum, 1000000000.0L / (long double)CLOCKS_PER_SEC);
    (void)warmup_observer;
    free(sample_ns);
    return 0;
}
