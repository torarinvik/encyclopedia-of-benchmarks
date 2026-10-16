/* Timed runner for float64 input slices that write float64 output slices. */
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

#define MAX_INPUT_LENGTH 273
#define MAX_OUTPUT_ELEMENTS 64
#define SENTINEL 0x1.5a5a5a5a5a5a5p+40
typedef int64_t (*slice_fn)(const double *, size_t, double *, size_t);
extern int64_t BENCHMARK_FUNCTION(const double *input, size_t input_len,
                                 double *output, size_t output_capacity);
static slice_fn volatile run_algorithm = BENCHMARK_FUNCTION;

static int read_u64(uint64_t *value)
{
    return scanf("%" SCNu64, value) == 1;
}

static int read_f64(double *value)
{
    return scanf("%lf", value) == 1 && isfinite(*value);
}

static int read_expected_f64(double *value)
{
    char token[128];
    char *end = NULL;
    if (scanf("%127s", token) != 1) return 0;
    if (strcmp(token, "NaN") == 0) {
        *value = NAN;
        return 1;
    }
    errno = 0;
    *value = strtod(token, &end);
    return errno != ERANGE && end != token && *end == '\0' && isfinite(*value);
}

static int matches(double actual, double expected, double absolute_tolerance,
                   double relative_tolerance)
{
    if (isnan(expected)) return isnan(actual);
    if (!isfinite(actual) || !isfinite(expected)) return 0;
    return fabs(actual - expected) <= absolute_tolerance + relative_tolerance * fabs(expected);
}

static int check_output(int64_t result, const double *output, size_t capacity,
                        int64_t expected_result, const double *expected_output,
                        size_t expected_length, double absolute_tolerance,
                        double relative_tolerance)
{
    if (result != expected_result) return 0;
    if (expected_result < 0) {
        for (size_t index = 0; index < capacity; ++index)
            if (output[index] != SENTINEL) return 0;
        return expected_length == 0;
    }
    if ((uint64_t)result != expected_length || expected_length > capacity) return 0;
    for (size_t index = 0; index < expected_length; ++index)
        if (!matches(output[index], expected_output[index], absolute_tolerance,
                     relative_tolerance)) return 0;
    for (size_t index = expected_length; index < capacity; ++index)
        if (output[index] != SENTINEL) return 0;
    return 1;
}

int main(int argc, char **argv)
{
    uint64_t samples_arg, warmups_arg, repetitions_arg;
    if (argc != 5 || strcmp(argv[1], "--stdin") != 0 ||
        sscanf(argv[2], "%" SCNu64, &samples_arg) != 1 ||
        sscanf(argv[3], "%" SCNu64, &warmups_arg) != 1 ||
        sscanf(argv[4], "%" SCNu64, &repetitions_arg) != 1 ||
        samples_arg == 0 || samples_arg > 10000 || warmups_arg > 100000 ||
        repetitions_arg == 0 || repetitions_arg > 1000000000) {
        fprintf(stderr, "usage: float64_slice_io_runner --stdin SAMPLES WARMUPS REPETITIONS\n");
        return 2;
    }

    uint64_t input_length_arg, expected_length_arg, output_capacity_arg;
    int64_t expected_result;
    double absolute_tolerance, relative_tolerance;
    if (!read_u64(&input_length_arg) || input_length_arg > MAX_INPUT_LENGTH ||
        scanf("%" SCNd64, &expected_result) != 1 || expected_result < -2 ||
        !read_u64(&expected_length_arg) || expected_length_arg > MAX_OUTPUT_ELEMENTS ||
        !read_u64(&output_capacity_arg) || output_capacity_arg > MAX_OUTPUT_ELEMENTS ||
        expected_length_arg > output_capacity_arg || !read_f64(&absolute_tolerance) ||
        absolute_tolerance < 0.0 || !read_f64(&relative_tolerance) || relative_tolerance < 0.0) {
        fprintf(stderr, "invalid float64-slice runner header\n");
        return 2;
    }

    const size_t input_length = (size_t)input_length_arg;
    const size_t expected_length = (size_t)expected_length_arg;
    const size_t output_capacity = (size_t)output_capacity_arg;
    double input[MAX_INPUT_LENGTH];
    double expected_output[MAX_OUTPUT_ELEMENTS];
    for (size_t index = 0; index < input_length; ++index)
        if (!read_f64(&input[index])) {
            fprintf(stderr, "invalid finite float64 input\n");
            return 2;
        }
    for (size_t index = 0; index < expected_length; ++index)
        if (!read_expected_f64(&expected_output[index])) {
            fprintf(stderr, "invalid float64 expected output\n");
            return 2;
        }
    char extra[2];
    if (scanf("%1s", extra) == 1 || ferror(stdin)) {
        fprintf(stderr, "unexpected trailing runner input\n");
        return 2;
    }

    double output[MAX_OUTPUT_ELEMENTS];
    for (size_t index = 0; index < MAX_OUTPUT_ELEMENTS; ++index) output[index] = SENTINEL;
    const double *input_pointer = input_length == 0 ? NULL : input;
    int64_t observed_result = run_algorithm(input_pointer, input_length, output, output_capacity);
    if (!check_output(observed_result, output, output_capacity, expected_result,
                      expected_output, expected_length, absolute_tolerance, relative_tolerance)) {
        fprintf(stderr, "correctness mismatch for float64-slice input\n");
        return 3;
    }

    const size_t sample_count = (size_t)samples_arg;
    uint64_t *sample_ns = malloc(sample_count * sizeof(*sample_ns));
    if (sample_ns == NULL) {
        fprintf(stderr, "unable to allocate sample data\n");
        return 2;
    }
    volatile uint64_t observer = 0;
    for (size_t warmup = 0; warmup < (size_t)warmups_arg; ++warmup) {
        for (size_t repetition = 0; repetition < (size_t)repetitions_arg; ++repetition)
            observed_result = run_algorithm(input_pointer, input_length, output, output_capacity);
        if (!check_output(observed_result, output, output_capacity, expected_result,
                          expected_output, expected_length, absolute_tolerance, relative_tolerance)) {
            fprintf(stderr, "output changed during warmup\n");
            free(sample_ns);
            return 3;
        }
        observer ^= (uint64_t)observed_result;
    }

    for (size_t sample = 0; sample < sample_count; ++sample) {
        const clock_t before = clock();
        if (before == (clock_t)-1) {
            fprintf(stderr, "clock() failed before a sample\n");
            free(sample_ns);
            return 4;
        }
        for (size_t repetition = 0; repetition < (size_t)repetitions_arg; ++repetition)
            observed_result = run_algorithm(input_pointer, input_length, output, output_capacity);
        const clock_t after = clock();
        if (after == (clock_t)-1 || after < before ||
            !check_output(observed_result, output, output_capacity, expected_result,
                          expected_output, expected_length, absolute_tolerance, relative_tolerance)) {
            fprintf(stderr, "clock() or output check failed during a sample\n");
            free(sample_ns);
            return 4;
        }
        const long double elapsed_ns =
            ((long double)(after - before) * 1000000000.0L) / (long double)CLOCKS_PER_SEC;
        sample_ns[sample] = (uint64_t)(elapsed_ns + 0.5L);
    }

    printf("{\"observed_result\":%" PRId64 ",\"observed_output\":[", observed_result);
    for (size_t index = 0; index < expected_length; ++index) {
        printf("%s", index == 0 ? "" : ",");
        if (isnan(output[index])) printf("\"NaN\"");
        else printf("%.17g", output[index]);
    }
    printf("],\"samples_ns\":[");
    for (size_t sample = 0; sample < sample_count; ++sample)
        printf("%s%" PRIu64, sample == 0 ? "" : ",", sample_ns[sample]);
    printf("],\"timer_resolution_ns\":%.3Lf}\n", 1000000000.0L / (long double)CLOCKS_PER_SEC);
    (void)observer;
    free(sample_ns);
    return 0;
}
