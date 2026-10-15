/* Batch checker for digit arrays whose algorithm writes ordered output bytes. */
#include <inttypes.h>
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
    while (checked < case_count) {
        uint64_t length, expected_bytes, output_capacity;
        int64_t expected_count;
        if (scanf("%" SCNu64 " %" SCNd64 " %" SCNu64,
                  &length, &expected_count, &expected_bytes) != 3 ||
            scanf("%" SCNu64, &output_capacity) != 1 ||
            length > MAX_INPUT_LENGTH || expected_bytes > output_capacity ||
            output_capacity > MAX_OUTPUT_BYTES ||
            expected_count < -2 || expected_count > 100000) {
            fprintf(stderr, "invalid output-array case header\n");
            return 2;
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
        observed[0] = UINT8_C(0xA5);
        const int64_t result = BENCHMARK_FUNCTION(values, (size_t)length, observed,
                                                   (size_t)output_capacity);
        if (result != expected_count ||
            (expected_bytes != 0 && memcmp(observed, expected, (size_t)expected_bytes) != 0) ||
            (output_capacity == 0 && observed[0] != UINT8_C(0xA5))) {
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
