/* Batch checker for signed scalar algorithms that write bytes to a caller buffer. */
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef BENCHMARK_FUNCTION
#error "Compile with -DBENCHMARK_FUNCTION=<exported function symbol>"
#endif

#define MAX_OUTPUT_BYTES 8192
extern int64_t BENCHMARK_FUNCTION(int64_t value, uint8_t *output, size_t output_capacity);

static int hex_value(char value)
{
    if (value >= '0' && value <= '9') return value - '0';
    if (value >= 'a' && value <= 'f') return value - 'a' + 10;
    if (value >= 'A' && value <= 'F') return value - 'A' + 10;
    return -1;
}

int main(void)
{
    uint64_t case_count;
    if (scanf("%" SCNu64, &case_count) != 1 || case_count == 0 || case_count > 1000000) {
        fprintf(stderr, "expected a nonempty case count\n");
        return 2;
    }

    for (uint64_t checked = 0; checked < case_count; ++checked) {
        int64_t input, expected_result;
        uint64_t capacity, output_length;
        char encoded[MAX_OUTPUT_BYTES * 2 + 2];
        if (scanf("%" SCNd64 " %" SCNd64 " %" SCNu64 " %" SCNu64 " %16384s",
                  &input, &expected_result, &capacity, &output_length, encoded) != 5 ||
            capacity > MAX_OUTPUT_BYTES || output_length > MAX_OUTPUT_BYTES ||
            expected_result < -2 || expected_result > MAX_OUTPUT_BYTES) {
            fprintf(stderr, "invalid scalar byte-output case header\n");
            return 2;
        }

        uint8_t expected[MAX_OUTPUT_BYTES], observed[MAX_OUTPUT_BYTES];
        memset(observed, UINT8_C(0xA5), sizeof(observed));
        if (output_length == 0) {
            if (strcmp(encoded, "-") != 0) {
                fprintf(stderr, "empty output must use the '-' marker\n");
                return 2;
            }
        } else {
            if (strlen(encoded) != output_length * 2) {
                fprintf(stderr, "expected output encoding has the wrong length\n");
                return 2;
            }
            for (size_t index = 0; index < (size_t)output_length; ++index) {
                const int high = hex_value(encoded[index * 2]);
                const int low = hex_value(encoded[index * 2 + 1]);
                if (high < 0 || low < 0) {
                    fprintf(stderr, "expected output encoding is not hexadecimal\n");
                    return 2;
                }
                expected[index] = (uint8_t)((high << 4) | low);
            }
        }

        const int64_t result = BENCHMARK_FUNCTION(input, observed, (size_t)capacity);
        if (result != expected_result ||
            (output_length > 0 && memcmp(observed, expected, (size_t)output_length) != 0)) {
            fprintf(stderr, "case=%" PRIu64 ": expected result=%" PRId64
                    ", observed=%" PRId64 "\n", checked, expected_result, result);
            return 3;
        }
        const size_t written = expected_result >= 0 ? (size_t)output_length : 0;
        for (size_t index = written; index < sizeof(observed); ++index) {
            if (observed[index] != UINT8_C(0xA5)) {
                fprintf(stderr, "case=%" PRIu64 ": output buffer was written past result\n", checked);
                return 3;
            }
        }
    }

    char extra;
    if (scanf(" %c", &extra) == 1 || ferror(stdin)) {
        fprintf(stderr, "unexpected trailing checker input\n");
        return 2;
    }
    printf("{\"cases_checked\":%" PRIu64 "}\n", case_count);
    return 0;
}
