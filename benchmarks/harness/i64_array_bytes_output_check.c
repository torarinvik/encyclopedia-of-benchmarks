/* Batch checker for digit arrays whose algorithm writes ordered output bytes. */
#include <inttypes.h>
#include <errno.h>
#include <float.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef BENCHMARK_FUNCTION
#error "Compile with -DBENCHMARK_FUNCTION=<exported function symbol>"
#endif

#define MAX_INPUT_LENGTH 100002
#define MAX_OUTPUT_BYTES 400004
extern int64_t BENCHMARK_FUNCTION(const int64_t *values, size_t length,
                                 uint8_t *output, size_t output_capacity);

static double decode_little_endian_f64(const uint8_t *bytes)
{
    uint64_t bits = 0;
    double value;
    for (size_t index = 0; index < 8; ++index)
        bits |= (uint64_t)bytes[index] << (8 * index);
    memcpy(&value, &bits, sizeof(value));
    return value;
}

static int finite_f64(double value)
{
    return value == value && value <= DBL_MAX && value >= -DBL_MAX;
}

static int output_matches(const uint8_t *observed, const uint8_t *expected,
                          size_t expected_bytes, int float64_vector,
                          double absolute_tolerance, double relative_tolerance)
{
    if (!float64_vector)
        return expected_bytes == 0 || memcmp(observed, expected, expected_bytes) == 0;
    if (expected_bytes % 8 != 0) return 0;
    for (size_t offset = 0; offset < expected_bytes; offset += 8) {
        const double actual = decode_little_endian_f64(observed + offset);
        const double reference = decode_little_endian_f64(expected + offset);
        const double difference = actual >= reference ? actual - reference : reference - actual;
        const double magnitude = reference >= 0.0 ? reference : -reference;
        const double allowed = absolute_tolerance + relative_tolerance * magnitude;
        if (!finite_f64(actual) || !finite_f64(reference) || !finite_f64(difference) ||
            !finite_f64(allowed) || difference > allowed) return 0;
    }
    return 1;
}

static int hex_value(char value)
{
    if (value >= '0' && value <= '9') return value - '0';
    if (value >= 'a' && value <= 'f') return value - 'a' + 10;
    if (value >= 'A' && value <= 'F') return value - 'A' + 10;
    return -1;
}

int main(void)
{
    uint64_t case_count, checked = 0;
    if (scanf("%" SCNu64, &case_count) != 1 || case_count == 0 || case_count > 1000000) {
        fprintf(stderr, "expected a nonempty case count\n");
        return 2;
    }
    int float64_vector = 0;
    int have_first_length = 0;
    uint64_t first_length = 0;
    double absolute_tolerance = 0.0, relative_tolerance = 0.0;
    char comparison_mode[32];
    if (scanf("%31s", comparison_mode) != 1) {
        fprintf(stderr, "missing checker comparison mode\n");
        return 2;
    }
    if (strcmp(comparison_mode, "float64_vector") == 0) {
        if (scanf("%lf %lf", &absolute_tolerance, &relative_tolerance) != 2 ||
            !finite_f64(absolute_tolerance) || absolute_tolerance < 0.0 ||
            !finite_f64(relative_tolerance) || relative_tolerance < 0.0) {
            fprintf(stderr, "invalid checker float64 tolerances\n");
            return 2;
        }
        float64_vector = 1;
    } else {
        char *end = NULL;
        errno = 0;
        const unsigned long long parsed_length = strtoull(comparison_mode, &end, 10);
        if (errno != 0 || end == comparison_mode || *end != '\0' ||
            parsed_length > MAX_INPUT_LENGTH) {
            fprintf(stderr, "invalid checker comparison mode or first case length\n");
            return 2;
        }
        first_length = (uint64_t)parsed_length;
        have_first_length = 1;
    }
    while (checked < case_count) {
        uint64_t length, expected_bytes, output_capacity, null_input_flag;
        int64_t expected_count;
        int header_result;
        if (checked == 0 && have_first_length) {
            length = first_length;
            header_result = scanf("%" SCNd64 " %" SCNu64,
                                  &expected_count, &expected_bytes) == 2 ? 3 : 0;
        } else {
            header_result = scanf("%" SCNu64 " %" SCNd64 " %" SCNu64,
                                  &length, &expected_count, &expected_bytes);
        }
        have_first_length = 0;
        if (header_result != 3 ||
            length > MAX_INPUT_LENGTH || expected_bytes > MAX_OUTPUT_BYTES ||
            expected_count < -2 || expected_count > 100000) {
            fprintf(stderr, "invalid output-array case header\n");
            return 2;
        }
#ifdef BENCHMARK_WORKSPACE_BYTES
        if (scanf("%" SCNu64, &output_capacity) != 1 ||
            expected_bytes > output_capacity || output_capacity > MAX_OUTPUT_BYTES) {
            fprintf(stderr, "invalid workspace capacity\n"); return 2;
        }
#else
        output_capacity = expected_bytes;
#endif
        if (scanf("%" SCNu64, &null_input_flag) != 1 || null_input_flag > 1 ||
            (null_input_flag != 0 && length == 0)) {
            fprintf(stderr, "invalid null-input flag\n"); return 2;
        }
        int64_t *values = length == 0 ? NULL : malloc((size_t)length * sizeof(*values));
        uint8_t *expected = malloc(expected_bytes == 0 ? 1 : (size_t)expected_bytes);
        uint8_t *observed = malloc(output_capacity == 0 ? 1 : (size_t)output_capacity);
        if ((length != 0 && values == NULL) || expected == NULL || observed == NULL) {
            free(values); free(expected); free(observed);
            fprintf(stderr, "unable to allocate case buffers\n");
            return 2;
        }
        for (size_t index = 0; index < (size_t)length; ++index) {
            if (scanf("%" SCNd64, &values[index]) != 1) {
                free(values); free(expected); free(observed);
                fprintf(stderr, "truncated input digits\n");
                return 2;
            }
        }
        int character;
        do { character = getchar(); } while (character != EOF &&
            (character == ' ' || character == '\t' || character == '\n' || character == '\r'));
        if (character == EOF) {
            free(values); free(expected); free(observed);
            fprintf(stderr, "missing expected output encoding\n"); return 2;
        }
        if (expected_bytes == 0) {
            if (character != '-') {
                free(values); free(expected); free(observed);
                fprintf(stderr, "empty output must use the '-' marker\n");
                return 2;
            }
            character = getchar();
            if (character != EOF && character != ' ' && character != '\t' &&
                character != '\n' && character != '\r') {
                free(values); free(expected); free(observed);
                fprintf(stderr, "empty output marker has trailing characters\n"); return 2;
            }
        } else {
            for (size_t index = 0; index < (size_t)expected_bytes; ++index) {
                const int high = hex_value((char)character);
                const int low_char = getchar();
                const int low = hex_value((char)low_char);
                if (high < 0 || low < 0) {
                    free(values); free(expected); free(observed);
                    fprintf(stderr, "expected output encoding is not hexadecimal\n");
                    return 2;
                }
                expected[index] = (uint8_t)((high << 4) | low);
                character = getchar();
            }
            if (character != EOF && character != ' ' && character != '\t' &&
                character != '\n' && character != '\r') {
                free(values); free(expected); free(observed);
                fprintf(stderr, "expected output encoding has trailing characters\n"); return 2;
            }
        }
        const size_t canary_length = output_capacity == 0 ? 1 : (size_t)output_capacity;
        memset(observed, 0xA5, canary_length);
        const int64_t result = BENCHMARK_FUNCTION(null_input_flag ? NULL : values,
                                                   (size_t)length, observed,
                                                   (size_t)output_capacity);
        int canary_changed = 0;
        if (null_input_flag || expected_count == -2 || output_capacity == 0) {
            for (size_t index = 0; index < canary_length; ++index) {
                if (observed[index] != UINT8_C(0xA5)) {
                    canary_changed = 1;
                    break;
                }
            }
        }
        if (result != expected_count ||
            !output_matches(observed, expected, (size_t)expected_bytes, float64_vector,
                            absolute_tolerance, relative_tolerance) ||
            ((null_input_flag || expected_count == -2 || output_capacity == 0) && canary_changed)) {
            fprintf(stderr, "case=%" PRIu64 ": expected count=%" PRId64
                    " output-bytes=%" PRIu64 ", capacity=%" PRIu64
                    ", observed count=%" PRId64 "\n",
                    checked, expected_count, expected_bytes, output_capacity, result);
            free(values); free(expected); free(observed);
            return 3;
        }
        free(values); free(expected); free(observed);
        ++checked;
    }
    char extra;
    if (scanf(" %c", &extra) == 1 || ferror(stdin)) {
        fprintf(stderr, "unexpected trailing checker input\n");
        return 2;
    }
    printf("{\"cases_checked\":%" PRIu64 "}\n", checked);
    return 0;
}
