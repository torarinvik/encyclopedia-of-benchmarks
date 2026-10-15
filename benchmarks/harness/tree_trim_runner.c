/* Timed caller-buffered BST trimming with an indexed-tree serialization. */
#include <errno.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#ifndef BENCHMARK_FUNCTION
#error "Compile with -DBENCHMARK_FUNCTION=<exported function symbol>"
#endif

#define MAX_NODE_COUNT 100
#define MAX_OUTPUT_VALUES (1 + 3 * MAX_NODE_COUNT)
#define OUTPUT_CANARY INT64_C(0x5A5A5A5A5A5A5A5A)
extern int64_t BENCHMARK_FUNCTION(const int64_t *, size_t, int64_t, int64_t, int64_t,
                                  int64_t *, size_t);

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

static uint64_t output_hash(const int64_t *output, size_t count)
{
    uint64_t hash = UINT64_C(14695981039346656037);
    for (size_t index = 0; index < count; ++index)
        hash = (hash ^ (uint64_t)output[index]) * UINT64_C(1099511628211);
    return hash;
}

static int64_t run_once(const int64_t *nodes, size_t node_count, int64_t root_index,
                        int64_t low, int64_t high, int64_t expected_result,
                        const int64_t *expected, size_t expected_count,
                        int64_t *output, size_t capacity, uint64_t *hash)
{
    for (size_t index = 0; index <= capacity; ++index) output[index] = OUTPUT_CANARY;
    const int64_t observed = BENCHMARK_FUNCTION(nodes, node_count, root_index, low, high,
                                                 output, capacity);
    int matches = observed == expected_result;
    if (observed >= 0) {
        matches = matches && (size_t)observed == expected_count &&
            (expected_count == 0 || memcmp(output, expected, expected_count * sizeof(*output)) == 0) &&
            (size_t)observed <= capacity && output[(size_t)observed] == OUTPUT_CANARY;
        if (matches) *hash = output_hash(output, (size_t)observed);
    } else {
        matches = matches && output[0] == OUTPUT_CANARY;
        *hash = 0;
    }
    if (!matches || output[capacity] != OUTPUT_CANARY) return INT64_MIN;
    return observed;
}

int main(int argc, char **argv)
{
    uint64_t samples_arg, warmups_arg, repetitions_arg;
    if (argc != 4 || !parse_u64(argv[1], &samples_arg) || !parse_u64(argv[2], &warmups_arg) ||
        !parse_u64(argv[3], &repetitions_arg) || samples_arg == 0 || samples_arg > 10000 ||
        warmups_arg > 100000 || repetitions_arg == 0 || repetitions_arg > 1000000000) {
        fprintf(stderr, "invalid tree-trim runner timing settings\n");
        return 2;
    }
    uint64_t node_count_arg, expected_count_arg, capacity_arg;
    int64_t root_index, low, high, expected_result;
    if (scanf("%" SCNu64 " %" SCNd64 " %" SCNd64 " %" SCNd64 " %" SCNd64
              " %" SCNu64 " %" SCNu64,
              &node_count_arg, &root_index, &low, &high, &expected_result,
              &expected_count_arg, &capacity_arg) != 7 ||
        node_count_arg > MAX_NODE_COUNT || expected_count_arg > MAX_OUTPUT_VALUES ||
        capacity_arg > MAX_OUTPUT_VALUES ||
        (expected_result >= 0 && expected_count_arg != (uint64_t)expected_result)) {
        fprintf(stderr, "invalid tree-trim runner header\n");
        return 2;
    }
    const size_t node_count = (size_t)node_count_arg;
    const size_t expected_count = (size_t)expected_count_arg;
    const size_t capacity = (size_t)capacity_arg;
    int64_t *nodes = node_count == 0 ? NULL : malloc(3 * node_count * sizeof(*nodes));
    int64_t *expected = expected_count == 0 ? NULL : malloc(expected_count * sizeof(*expected));
    int64_t output[MAX_OUTPUT_VALUES + 1];
    uint64_t *sample_ns = malloc((size_t)samples_arg * sizeof(*sample_ns));
    if ((node_count != 0 && nodes == NULL) || (expected_count != 0 && expected == NULL) ||
        sample_ns == NULL) {
        free(nodes); free(expected); free(sample_ns);
        fprintf(stderr, "unable to allocate tree-trim runner buffers\n");
        return 2;
    }
    for (size_t index = 0; index < 3 * node_count; ++index) {
        if (scanf("%" SCNd64, &nodes[index]) != 1) {
            free(nodes); free(expected); free(sample_ns);
            fprintf(stderr, "truncated indexed tree input\n");
            return 2;
        }
    }
    for (size_t index = 0; index < expected_count; ++index) {
        if (scanf("%" SCNd64, &expected[index]) != 1) {
            free(nodes); free(expected); free(sample_ns);
            fprintf(stderr, "truncated expected serialized tree\n");
            return 2;
        }
    }
    char extra;
    if (scanf(" %c", &extra) == 1 || ferror(stdin)) {
        free(nodes); free(expected); free(sample_ns);
        fprintf(stderr, "unexpected trailing tree-trim workload input\n");
        return 2;
    }

    uint64_t hash = 0;
    int64_t observed = run_once(nodes, node_count, root_index, low, high, expected_result,
                                expected, expected_count, output, capacity, &hash);
    if (observed == INT64_MIN) {
        free(nodes); free(expected); free(sample_ns);
        fprintf(stderr, "tree-trim output does not match expected serialization\n");
        return 3;
    }
    for (uint64_t warmup = 0; warmup < warmups_arg; ++warmup) {
        for (uint64_t repetition = 0; repetition < repetitions_arg; ++repetition) {
            if (run_once(nodes, node_count, root_index, low, high, expected_result,
                         expected, expected_count, output, capacity, &hash) != observed) {
                free(nodes); free(expected); free(sample_ns);
                fprintf(stderr, "tree-trim output changed during warmup\n");
                return 3;
            }
        }
    }
    uint64_t total_checksum = 0;
    for (uint64_t sample = 0; sample < samples_arg; ++sample) {
        const clock_t start = clock();
        if (start == (clock_t)-1) {
            free(nodes); free(expected); free(sample_ns);
            fprintf(stderr, "clock() failed before a sample\n");
            return 4;
        }
        uint64_t sample_checksum = 0;
        for (uint64_t repetition = 0; repetition < repetitions_arg; ++repetition) {
            uint64_t current_hash = 0;
            const int64_t result = run_once(nodes, node_count, root_index, low, high,
                                            expected_result, expected, expected_count,
                                            output, capacity, &current_hash);
            if (result != observed) {
                free(nodes); free(expected); free(sample_ns);
                fprintf(stderr, "tree-trim output changed during measurement\n");
                return 4;
            }
            sample_checksum += current_hash;
        }
        const clock_t finish = clock();
        if (finish == (clock_t)-1 || finish < start) {
            free(nodes); free(expected); free(sample_ns);
            fprintf(stderr, "clock() failed during a sample\n");
            return 4;
        }
        total_checksum += sample_checksum;
        const long double elapsed_ns =
            ((long double)(finish - start) * 1000000000.0L) / (long double)CLOCKS_PER_SEC;
        sample_ns[sample] = (uint64_t)(elapsed_ns + 0.5L);
    }
    printf("{\"observed_result\":%" PRId64 ",\"samples_ns\":[", observed);
    for (uint64_t sample = 0; sample < samples_arg; ++sample)
        printf("%s%" PRIu64, sample == 0 ? "" : ",", sample_ns[sample]);
    printf("],\"result_checksum\":%" PRIu64 ",\"timer_resolution_ns\":%.3Lf}\n",
           total_checksum, 1000000000.0L / (long double)CLOCKS_PER_SEC);
    free(nodes); free(expected); free(sample_ns);
    return 0;
}
