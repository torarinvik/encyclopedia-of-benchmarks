/* Timed runner for a binary64 function with a signed 32-bit exponent. */
#include <errno.h>
#include <float.h>
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

typedef double (*benchmark_fn)(double, int32_t);
extern double BENCHMARK_FUNCTION(double, int32_t);
static benchmark_fn volatile run_algorithm = BENCHMARK_FUNCTION;

_Static_assert(sizeof(double) == sizeof(uint64_t) && DBL_MANT_DIG == 53 && DBL_MAX_EXP == 1024,
               "float64_i32 requires IEEE 754 binary64 double");

static int parse_f64(const char *text, double *value)
{
    char *end = NULL;
    if (text[0] == '\0') return 0;
    errno = 0;
    const double parsed = strtod(text, &end);
    if (end == text || *end != '\0' || !isfinite(parsed)) return 0;
    *value = parsed;
    return 1;
}

static int parse_i32(const char *text, int32_t *value)
{
    char *end = NULL;
    if (text[0] == '\0') return 0;
    errno = 0;
    const long parsed = strtol(text, &end, 10);
    if (errno == ERANGE || end == text || *end != '\0' || parsed < INT32_MIN || parsed > INT32_MAX)
        return 0;
    *value = (int32_t)parsed;
    return 1;
}

static int parse_u64(const char *text, uint64_t *value)
{
    char *end = NULL;
    if (text[0] == '-' || text[0] == '\0') return 0;
    errno = 0;
    const unsigned long long parsed = strtoull(text, &end, 10);
    if (errno == ERANGE || end == text || *end != '\0') return 0;
    *value = (uint64_t)parsed;
    return 1;
}

static int matches(double observed, double expected, double relative_tolerance)
{
    if (!isfinite(observed)) return 0;
    if (expected == 0.0)
        return observed == 0.0 && signbit(observed) == signbit(expected);
    return fabs(observed - expected) <= relative_tolerance * fabs(expected);
}

static uint64_t result_bits(double value)
{
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    return bits;
}

static double run_batch(double base, int32_t exponent, size_t repetitions, uint64_t *checksum)
{
    double result = 0.0;
    uint64_t local_checksum = 0;
    for (size_t repetition = 0; repetition < repetitions; ++repetition) {
        result = run_algorithm(base, exponent);
        local_checksum += result_bits(result);
    }
    *checksum = local_checksum;
    return result;
}

static void print_double(double value)
{
    if (value == 0.0 && signbit(value)) fputs("-0.0", stdout);
    else printf("%.17g", value);
}

int main(int argc, char **argv)
{
    double base, expected, relative_tolerance;
    int32_t exponent;
    uint64_t samples_arg, warmups_arg, repetitions_arg;
    if (argc != 8 || !parse_f64(argv[1], &base) || !(base > -100.0 && base < 100.0) ||
        !parse_i32(argv[2], &exponent) || (base == 0.0 && exponent < 0) ||
        !parse_f64(argv[3], &expected) || expected < -10000.0 || expected > 10000.0 ||
        !parse_f64(argv[4], &relative_tolerance) || relative_tolerance <= 0.0 ||
        !parse_u64(argv[5], &samples_arg) || !parse_u64(argv[6], &warmups_arg) ||
        !parse_u64(argv[7], &repetitions_arg) || samples_arg == 0 || samples_arg > 10000 ||
        warmups_arg > 100000 || repetitions_arg == 0 || repetitions_arg > 1000000000) {
        fprintf(stderr, "usage: float64_i32_runner BASE EXPONENT EXPECTED REL_TOL SAMPLES WARMUPS REPETITIONS\n");
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
    if (!matches(run_algorithm(base, exponent), expected, relative_tolerance)) {
        fprintf(stderr, "correctness mismatch for binary64 base and int32 exponent\n");
        free(sample_ns);
        return 3;
    }
    volatile uint64_t warmup_observer = 0;
    for (size_t warmup = 0; warmup < warmup_count; ++warmup) {
        uint64_t checksum = 0;
        if (!matches(run_batch(base, exponent, repetitions, &checksum), expected, relative_tolerance)) {
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
        observed_result = run_batch(base, exponent, repetitions, &checksum);
        const clock_t after = clock();
        if (after == (clock_t)-1 || after < before ||
            !matches(observed_result, expected, relative_tolerance)) {
            fprintf(stderr, "clock() or result check failed during a sample\n");
            free(sample_ns);
            return 4;
        }
        total_checksum += checksum;
        const long double elapsed_ns =
            ((long double)(after - before) * 1000000000.0L) / (long double)CLOCKS_PER_SEC;
        sample_ns[sample] = (uint64_t)(elapsed_ns + 0.5L);
    }
    fputs("{\"observed_result\":", stdout);
    print_double(observed_result);
    printf(",\"observed_bits\":\"%016" PRIx64 "\",\"samples_ns\":[", result_bits(observed_result));
    for (size_t sample = 0; sample < sample_count; ++sample)
        printf("%s%" PRIu64, sample == 0 ? "" : ",", sample_ns[sample]);
    printf("],\"result_checksum\":%" PRIu64 ",\"timer_resolution_ns\":%.3Lf}\n",
           total_checksum, 1000000000.0L / (long double)CLOCKS_PER_SEC);
    (void)warmup_observer;
    free(sample_ns);
    return 0;
}
