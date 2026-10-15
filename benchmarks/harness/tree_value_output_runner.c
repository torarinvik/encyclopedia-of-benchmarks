/* Timed caller-buffered value traversal for an indexed binary tree. */
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
#define OUTPUT_CANARY INT64_C(0x5A5A5A5A5A5A5A5A)
typedef int64_t (*tree_output_fn)(const int64_t *, size_t, int64_t, int64_t *, size_t);
extern int64_t BENCHMARK_FUNCTION(const int64_t *, size_t, int64_t, int64_t *, size_t);
static tree_output_fn volatile run_algorithm = BENCHMARK_FUNCTION;

static int parse_i64(const char *text, int64_t *value)
{
    char *end = NULL;
    errno = 0;
    const long long parsed = strtoll(text, &end, 10);
    if (text[0] == '\0' || errno == ERANGE || end == text || *end != '\0') return 0;
    *value = (int64_t)parsed;
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

static uint64_t checksum(const int64_t *values, size_t count)
{
    uint64_t hash = UINT64_C(14695981039346656037);
    for (size_t index = 0; index < count; ++index)
        hash = (hash ^ (uint64_t)values[index]) * UINT64_C(1099511628211);
    return hash;
}

static int64_t run_batch(const int64_t *nodes, size_t node_count, int64_t root_index,
                         int64_t *output, size_t capacity, size_t repetitions,
                         uint64_t *output_hash)
{
    int64_t result = 0;
    uint64_t hash = 0;
    for (size_t repetition = 0; repetition < repetitions; ++repetition) {
        result = run_algorithm(nodes, node_count, root_index, output, capacity);
        if (result > 0) hash ^= checksum(output, (size_t)result);
    }
    *output_hash = hash;
    return result;
}

int main(int argc, char **argv)
{
    uint64_t samples_arg, warmups_arg, repetitions_arg;
    int64_t expected_result;
    if (argc != 5 || !parse_i64(argv[1], &expected_result) ||
        !parse_u64(argv[2], &samples_arg) || !parse_u64(argv[3], &warmups_arg) ||
        !parse_u64(argv[4], &repetitions_arg) || samples_arg == 0 || samples_arg > 10000 ||
        warmups_arg > 100000 || repetitions_arg == 0 || repetitions_arg > 1000000000) {
        fprintf(stderr, "invalid runner timing settings\n");
        return 2;
    }
    uint64_t node_count_arg, expected_count_arg, capacity_arg;
    int64_t root_index;
    if (scanf("%" SCNu64 " %" SCNd64 " %" SCNu64 " %" SCNu64,
              &node_count_arg, &root_index, &expected_count_arg, &capacity_arg) != 4 ||
        node_count_arg > MAX_NODE_COUNT || expected_count_arg > MAX_NODE_COUNT ||
        capacity_arg > MAX_NODE_COUNT || expected_count_arg != (expected_result < 0 ? 0 : (uint64_t)expected_result)) {
        fprintf(stderr, "invalid tree runner header\n");
        return 2;
    }
    const size_t node_count = (size_t)node_count_arg;
    const size_t expected_count = (size_t)expected_count_arg;
    const size_t capacity = (size_t)capacity_arg;
    const size_t sample_count = (size_t)samples_arg;
    const size_t warmup_count = (size_t)warmups_arg;
    const size_t repetitions = (size_t)repetitions_arg;
    int64_t *nodes = node_count == 0 ? NULL : malloc(3 * node_count * sizeof(*nodes));
    int64_t *expected = expected_count == 0 ? NULL : malloc(expected_count * sizeof(*expected));
    int64_t *output = malloc((node_count + 1) * sizeof(*output));
    uint64_t *sample_ns = malloc(sample_count * sizeof(*sample_ns));
    if ((node_count != 0 && nodes == NULL) || (expected_count != 0 && expected == NULL) ||
        output == NULL || sample_ns == NULL) {
        fprintf(stderr, "unable to allocate tree runner buffers\n");
        free(nodes); free(expected); free(output); free(sample_ns); return 2;
    }
    for (size_t index = 0; index < 3 * node_count; ++index) {
        if (scanf("%" SCNd64, &nodes[index]) != 1) {
            fprintf(stderr, "truncated tree node table\n");
            free(nodes); free(expected); free(output); free(sample_ns); return 2;
        }
    }
    for (size_t index = 0; index < expected_count; ++index) {
        if (scanf("%" SCNd64, &expected[index]) != 1) {
            fprintf(stderr, "truncated expected traversal values\n");
            free(nodes); free(expected); free(output); free(sample_ns); return 2;
        }
    }
    char extra;
    if (scanf(" %c", &extra) == 1 || ferror(stdin)) {
        fprintf(stderr, "unexpected trailing tree workload input\n");
        free(nodes); free(expected); free(output); free(sample_ns); return 2;
    }
    for (size_t index = 0; index <= node_count; ++index) output[index] = OUTPUT_CANARY;
    int64_t observed = run_algorithm(nodes, node_count, root_index, output, capacity);
    if (observed != expected_result || (observed >= 0 && (size_t)observed != expected_count) ||
        (observed > 0 && memcmp(output, expected, (size_t)observed * sizeof(*output)) != 0) ||
        (observed >= 0 && output[(size_t)observed] != OUTPUT_CANARY) ||
        (observed < 0 && output[0] != OUTPUT_CANARY)) {
        fprintf(stderr, "tree traversal correctness mismatch\n");
        free(nodes); free(expected); free(output); free(sample_ns); return 3;
    }
    volatile uint64_t warmup_observer = 0;
    for (size_t warmup = 0; warmup < warmup_count; ++warmup) {
        uint64_t hash = 0;
        if (run_batch(nodes, node_count, root_index, output, capacity, repetitions, &hash) != expected_result) {
            fprintf(stderr, "algorithm result changed during warmup\n");
            free(nodes); free(expected); free(output); free(sample_ns); return 3;
        }
        warmup_observer ^= hash;
    }
    uint64_t total_checksum = 0;
    for (size_t sample = 0; sample < sample_count; ++sample) {
        const clock_t start = clock();
        if (start == (clock_t)-1) {
            fprintf(stderr, "clock() failed before a sample\n");
            free(nodes); free(expected); free(output); free(sample_ns); return 4;
        }
        uint64_t hash = 0;
        observed = run_batch(nodes, node_count, root_index, output, capacity, repetitions, &hash);
        const clock_t finish = clock();
        if (finish == (clock_t)-1 || finish < start || observed != expected_result ||
            (observed > 0 && memcmp(output, expected, (size_t)observed * sizeof(*output)) != 0)) {
            fprintf(stderr, "clock or output check failed during a sample\n");
            free(nodes); free(expected); free(output); free(sample_ns); return 4;
        }
        total_checksum ^= hash;
        const long double elapsed_ns =
            ((long double)(finish - start) * 1000000000.0L) / (long double)CLOCKS_PER_SEC;
        sample_ns[sample] = (uint64_t)(elapsed_ns + 0.5L);
    }
    printf("{\"observed_result\":%" PRId64 ",\"observed_values\":[", observed);
    for (int64_t index = 0; index < observed; ++index)
        printf("%s%" PRId64, index == 0 ? "" : ",", output[index]);
    printf("],\"samples_ns\":[");
    for (size_t sample = 0; sample < sample_count; ++sample)
        printf("%s%" PRIu64, sample == 0 ? "" : ",", sample_ns[sample]);
    printf("],\"result_checksum\":%" PRIu64 ",\"timer_resolution_ns\":%.3Lf}\n",
           total_checksum, 1000000000.0L / (long double)CLOCKS_PER_SEC);
    (void)warmup_observer;
    free(nodes); free(expected); free(output); free(sample_ns);
    return 0;
}
