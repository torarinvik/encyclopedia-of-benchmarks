/* Batch checker for digit arrays whose algorithm writes ordered output bytes. */
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef BENCHMARK_FUNCTION
#error "Compile with -DBENCHMARK_FUNCTION=<exported function symbol>"
#endif

#define MAX_INPUT_LENGTH 66
#define MAX_OUTPUT_BYTES 24576
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
        uint64_t length, output_bytes;
        int64_t expected_count;
        if (scanf("%" SCNu64 " %" SCNd64 " %" SCNu64,
                  &length, &expected_count, &output_bytes) != 3 ||
            length > MAX_INPUT_LENGTH || output_bytes > MAX_OUTPUT_BYTES ||
            expected_count < -2 || expected_count > 4096) {
            fprintf(stderr, "invalid output-array case header\n");
            return 2;
        }
        int64_t *values = length == 0 ? NULL : malloc((size_t)length * sizeof(*values));
        uint8_t *expected = malloc(output_bytes == 0 ? 1 : (size_t)output_bytes);
        uint8_t *observed = malloc(output_bytes == 0 ? 1 : (size_t)output_bytes);
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
        char encoded[MAX_OUTPUT_BYTES * 2 + 2];
        if (scanf("%49152s", encoded) != 1) {
            free(values); free(expected); free(observed);
            fprintf(stderr, "missing expected output encoding\n");
            return 2;
        }
        if (output_bytes == 0) {
            if (strcmp(encoded, "-") != 0) {
                free(values); free(expected); free(observed);
                fprintf(stderr, "empty output must use the '-' marker\n");
                return 2;
            }
        } else {
            if (strlen(encoded) != output_bytes * 2) {
                free(values); free(expected); free(observed);
                fprintf(stderr, "expected output encoding has the wrong length\n");
                return 2;
            }
            for (size_t index = 0; index < (size_t)output_bytes; ++index) {
                const int high = hex_value(encoded[2 * index]);
                const int low = hex_value(encoded[2 * index + 1]);
                if (high < 0 || low < 0) {
                    free(values); free(expected); free(observed);
                    fprintf(stderr, "expected output encoding is not hexadecimal\n");
                    return 2;
                }
                expected[index] = (uint8_t)((high << 4) | low);
            }
        }
        observed[0] = UINT8_C(0xA5);
        const int64_t result = BENCHMARK_FUNCTION(values, (size_t)length, observed,
                                                   (size_t)output_bytes);
        if (result != expected_count ||
            (output_bytes != 0 && memcmp(observed, expected, (size_t)output_bytes) != 0) ||
            (output_bytes == 0 && observed[0] != UINT8_C(0xA5))) {
            fprintf(stderr, "case=%" PRIu64 ": expected count=%" PRId64
                    " bytes=%" PRIu64 ", observed count=%" PRId64 "\n",
                    checked, expected_count, output_bytes, result);
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
