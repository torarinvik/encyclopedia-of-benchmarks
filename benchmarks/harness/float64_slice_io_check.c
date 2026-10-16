/* Batch ABI checker for float64 input and output slices. */
#include <float.h>
#include <errno.h>
#include <inttypes.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef BENCHMARK_FUNCTION
#error "Compile with -DBENCHMARK_FUNCTION=<exported function symbol>"
#endif

#define MAX_INPUT_LENGTH 64
#define MAX_OUTPUT_ELEMENTS 64
#define SENTINEL 0x1.5a5a5a5a5a5a5p+40
extern int64_t BENCHMARK_FUNCTION(const double *input, size_t input_len,
                                 double *output, size_t output_capacity);

_Static_assert(sizeof(double) == sizeof(uint64_t) && DBL_MANT_DIG == 53 && DBL_MAX_EXP == 1024,
               "float64_slice_io requires IEEE 754 binary64 double");

static int read_f64(double *value)
{
    /* Inputs may include NaN or infinity so implementations can reject them
       according to their own ABI contract. */
    return scanf("%lf", value) == 1;
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
    return isfinite(actual) && isfinite(expected) &&
        fabs(actual - expected) <= absolute_tolerance + relative_tolerance * fabs(expected);
}

int main(void)
{
    uint64_t case_count, workspace_arg, checked = 0;
    double absolute_tolerance, relative_tolerance;
    if (scanf("%" SCNu64 " %lf %lf %" SCNu64, &case_count, &absolute_tolerance,
              &relative_tolerance, &workspace_arg) != 4 || case_count == 0 ||
        case_count > 1000000 || !isfinite(absolute_tolerance) || absolute_tolerance < 0.0 ||
        !isfinite(relative_tolerance) || relative_tolerance < 0.0 ||
        workspace_arg == 0 || workspace_arg > MAX_OUTPUT_ELEMENTS) {
        fprintf(stderr, "invalid float64-slice checker header\n");
        return 2;
    }
    const size_t workspace = (size_t)workspace_arg;
    while (checked < case_count) {
        uint64_t input_length_arg, expected_length_arg, capacity_arg, input_null_arg, output_null_arg;
        int64_t expected_result;
        if (scanf("%" SCNu64 " %" SCNd64 " %" SCNu64 " %" SCNu64 " %" SCNu64 " %" SCNu64,
                  &input_length_arg, &expected_result, &expected_length_arg, &capacity_arg,
                  &input_null_arg, &output_null_arg) != 6 ||
            input_length_arg > MAX_INPUT_LENGTH || expected_result < -2 ||
            expected_length_arg > workspace || capacity_arg > workspace ||
            expected_length_arg > capacity_arg || input_null_arg > 1 || output_null_arg > 1 ||
            (expected_result >= 0 && expected_result != (int64_t)expected_length_arg) ||
            (expected_result < 0 && expected_length_arg != 0) ||
            (input_null_arg != 0 && input_length_arg == 0) ||
            (output_null_arg != 0 && expected_result != -2)) {
            fprintf(stderr, "invalid float64-slice case header\n");
            return 2;
        }
        double input_storage[MAX_INPUT_LENGTH];
        double expected_output[MAX_OUTPUT_ELEMENTS];
        for (size_t index = 0; index < (size_t)input_length_arg; ++index)
            if (!read_f64(&input_storage[index])) {
                fprintf(stderr, "invalid finite float64 input\n");
                return 2;
            }
        for (size_t index = 0; index < (size_t)expected_length_arg; ++index)
            if (!read_expected_f64(&expected_output[index])) {
                fprintf(stderr, "invalid expected output\n");
                return 2;
            }
        double output[MAX_OUTPUT_ELEMENTS];
        for (size_t index = 0; index < workspace; ++index) output[index] = SENTINEL;
        const double *input = input_null_arg != 0 ? NULL :
                              input_length_arg == 0 ? NULL : input_storage;
        double *output_pointer = output_null_arg != 0 ? NULL : output;
        const int64_t observed = BENCHMARK_FUNCTION(input, (size_t)input_length_arg,
                                                    output_pointer, (size_t)capacity_arg);
        if (observed != expected_result) {
            fprintf(stderr, "case=%" PRIu64 ": expected status/result=%" PRId64
                    ", observed=%" PRId64 "\n", checked, expected_result, observed);
            return 3;
        }
        if (expected_result < 0) {
            for (size_t index = 0; index < workspace; ++index)
                if (output[index] != SENTINEL) {
                    fprintf(stderr, "case=%" PRIu64 ": failure status modified output\n", checked);
                    return 3;
                }
        } else {
            for (size_t index = 0; index < (size_t)expected_length_arg; ++index)
                if (!matches(output[index], expected_output[index], absolute_tolerance,
                             relative_tolerance)) {
                    fprintf(stderr, "case=%" PRIu64 ": output[%zu] mismatch\n", checked, index);
                    return 3;
                }
            for (size_t index = (size_t)expected_length_arg; index < workspace; ++index)
                if (output[index] != SENTINEL) {
                    fprintf(stderr, "case=%" PRIu64 ": output tail was modified\n", checked);
                    return 3;
                }
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
