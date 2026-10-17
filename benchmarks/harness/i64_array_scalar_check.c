/* Batch checker for scalar algorithms that consume a read-only i64 array. */
#include <inttypes.h>
#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef BENCHMARK_FUNCTION
#error "Compile with -DBENCHMARK_FUNCTION=<exported function symbol>"
#endif

extern int64_t BENCHMARK_FUNCTION(const int64_t *values, size_t length);

int main(void)
{
    uint64_t case_count, checked = 0;
    if (scanf("%" SCNu64, &case_count) != 1 || case_count == 0 || case_count > 1000000) {
        fprintf(stderr, "expected a nonempty case count\n");
        return 2;
    }
    while (checked < case_count) {
        uint64_t length;
        int64_t expected;
        char length_token[32];
        if (scanf("%31s", length_token) != 1) {
            fprintf(stderr, "invalid array case header\n");
            return 2;
        }
        const int null_input = strcmp(length_token, "NULL") == 0;
        if (null_input) {
            if (scanf("%" SCNu64 " %" SCNd64, &length, &expected) != 2
                    || length > 100002) {
                fprintf(stderr, "invalid null array case header\n");
                return 2;
            }
        } else {
            char *end = NULL;
            errno = 0;
            const unsigned long long parsed_length = strtoull(length_token, &end, 10);
            if (errno != 0 || end == length_token || *end != '\0'
                    || parsed_length > 100002
                    || scanf("%" SCNd64, &expected) != 1) {
                fprintf(stderr, "invalid array case header\n");
                return 2;
            }
            length = (uint64_t)parsed_length;
        }
        int64_t *values = null_input || length == 0
                ? NULL : malloc((size_t)length * sizeof(*values));
        if (!null_input && length != 0 && values == NULL) {
            fprintf(stderr, "unable to allocate checker input\n");
            return 2;
        }
        for (size_t index = 0; !null_input && index < (size_t)length; ++index) {
            if (scanf("%" SCNd64, &values[index]) != 1) {
                free(values);
                fprintf(stderr, "truncated array input\n");
                return 2;
            }
        }
        const int64_t observed = BENCHMARK_FUNCTION(null_input ? NULL : values, (size_t)length);
        free(values);
        if (observed != expected) {
            fprintf(stderr, "case=%" PRIu64 ": expected %" PRId64 ", observed %" PRId64 "\n",
                    checked, expected, observed);
            return 3;
        }
        ++checked;
    }
    uint64_t extra;
    if (scanf("%" SCNu64, &extra) == 1 || ferror(stdin)) {
        fprintf(stderr, "unexpected trailing checker input\n");
        return 2;
    }
    printf("{\"cases_checked\":%" PRIu64 "}\n", checked);
    return 0;
}
