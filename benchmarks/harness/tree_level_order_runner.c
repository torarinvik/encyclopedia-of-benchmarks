/* Timed BFS runner for an indexed binary tree with caller-provided storage. */
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

#define MAX_NODE_COUNT 4096
typedef int64_t (*tree_fn)(const int64_t *, size_t, int64_t, int64_t *, size_t,
                           size_t *, size_t, size_t *, size_t);
extern int64_t BENCHMARK_FUNCTION(const int64_t *nodes, size_t node_count, int64_t root_index,
                                  int64_t *output_values, size_t output_capacity,
                                  size_t *level_offsets, size_t level_offsets_capacity,
                                  size_t *queue, size_t queue_capacity);
static tree_fn volatile run_algorithm = BENCHMARK_FUNCTION;

static int parse_i64(const char *text, int64_t *value)
{
    char *end = NULL;
    long long parsed;
    if (text[0] == '\0') return 0;
    errno = 0;
    parsed = strtoll(text, &end, 10);
    if (errno == ERANGE || end == text || *end != '\0') return 0;
    *value = (int64_t)parsed;
    return 1;
}

static int parse_u64(const char *text, uint64_t *value)
{
    char *end = NULL;
    unsigned long long parsed;
    if (text[0] == '-' || text[0] == '\0') return 0;
    errno = 0;
    parsed = strtoull(text, &end, 10);
    if (errno == ERANGE || end == text || *end != '\0') return 0;
    *value = (uint64_t)parsed;
    return 1;
}

static uint64_t checksum_outputs(const int64_t *values, size_t value_count,
                                 const size_t *offsets, size_t offset_count)
{
    uint64_t hash = UINT64_C(14695981039346656037);
    for (size_t index = 0; index < value_count; ++index)
        hash = (hash ^ (uint64_t)values[index]) * UINT64_C(1099511628211);
    for (size_t index = 0; index < offset_count; ++index)
        hash = (hash ^ (uint64_t)offsets[index]) * UINT64_C(1099511628211);
    return hash;
}

int main(int argc, char **argv)
{
    uint64_t expected_levels_arg, samples_arg, warmups_arg, repetitions_arg, node_count_arg;
    int64_t root_index;
    if (argc != 5 || !parse_u64(argv[1], &expected_levels_arg) ||
        !parse_u64(argv[2], &samples_arg) || !parse_u64(argv[3], &warmups_arg) ||
        !parse_u64(argv[4], &repetitions_arg) || expected_levels_arg > MAX_NODE_COUNT ||
        samples_arg == 0 || samples_arg > 10000 || warmups_arg > 100000 ||
        repetitions_arg == 0 || repetitions_arg > 1000000000 ||
        scanf("%" SCNu64 " %" SCNd64, &node_count_arg, &root_index) != 2 ||
        node_count_arg > MAX_NODE_COUNT || expected_levels_arg > node_count_arg) {
        fprintf(stderr, "invalid tree runner header or timing settings\n");
        return 2;
    }
    const size_t node_count = (size_t)node_count_arg;
    const size_t expected_levels = (size_t)expected_levels_arg;
    const size_t sample_count = (size_t)samples_arg;
    const size_t warmup_count = (size_t)warmups_arg;
    const size_t repetitions = (size_t)repetitions_arg;
    int64_t *nodes = node_count == 0 ? NULL : malloc(3 * node_count * sizeof(*nodes));
    int64_t *expected_values = node_count == 0 ? NULL : malloc(node_count * sizeof(*expected_values));
    int64_t *output_values = malloc((node_count == 0 ? 1 : node_count) * sizeof(*output_values));
    size_t *expected_offsets = malloc((node_count + 1) * sizeof(*expected_offsets));
    size_t *level_offsets = malloc((node_count + 1) * sizeof(*level_offsets));
    size_t *queue = malloc((node_count == 0 ? 1 : node_count) * sizeof(*queue));
    uint64_t *sample_ns = malloc(sample_count * sizeof(*sample_ns));
    if ((node_count != 0 && (nodes == NULL || expected_values == NULL)) || output_values == NULL ||
        expected_offsets == NULL || level_offsets == NULL || queue == NULL || sample_ns == NULL) {
        fprintf(stderr, "unable to allocate tree runner buffers\n");
        free(nodes); free(expected_values); free(output_values); free(expected_offsets);
        free(level_offsets); free(queue); free(sample_ns); return 2;
    }
    for (size_t index = 0; index < 3 * node_count; ++index) {
        if (scanf("%" SCNd64, &nodes[index]) != 1) {
            fprintf(stderr, "truncated tree node data\n");
            free(nodes); free(expected_values); free(output_values); free(expected_offsets);
            free(level_offsets); free(queue); free(sample_ns); return 2;
        }
    }
    for (size_t index = 0; index < node_count; ++index) {
        if (scanf("%" SCNd64, &expected_values[index]) != 1) {
            fprintf(stderr, "truncated expected traversal values\n");
            free(nodes); free(expected_values); free(output_values); free(expected_offsets);
            free(level_offsets); free(queue); free(sample_ns); return 2;
        }
    }
    uint64_t offset_count_arg;
    if (scanf("%" SCNu64, &offset_count_arg) != 1 || offset_count_arg != expected_levels + 1) {
        fprintf(stderr, "expected one more level offset than level count\n");
        free(nodes); free(expected_values); free(output_values); free(expected_offsets);
        free(level_offsets); free(queue); free(sample_ns); return 2;
    }
    const size_t offset_count = (size_t)offset_count_arg;
    for (size_t index = 0; index < offset_count; ++index) {
        uint64_t value;
        if (scanf("%" SCNu64, &value) != 1 || value > node_count) {
            fprintf(stderr, "invalid expected level offset\n");
            free(nodes); free(expected_values); free(output_values); free(expected_offsets);
            free(level_offsets); free(queue); free(sample_ns); return 2;
        }
        expected_offsets[index] = (size_t)value;
    }
    char extra;
    if (scanf(" %c", &extra) == 1 || ferror(stdin)) {
        fprintf(stderr, "unexpected trailing tree workload input\n");
        free(nodes); free(expected_values); free(output_values); free(expected_offsets);
        free(level_offsets); free(queue); free(sample_ns); return 2;
    }
    if (run_algorithm(nodes, node_count, root_index, output_values, node_count,
                      level_offsets, node_count + 1, queue, node_count) != (int64_t)expected_levels ||
        (node_count != 0 && memcmp(output_values, expected_values, node_count * sizeof(*output_values)) != 0) ||
        memcmp(level_offsets, expected_offsets, offset_count * sizeof(*level_offsets)) != 0) {
        fprintf(stderr, "tree traversal correctness mismatch\n");
        free(nodes); free(expected_values); free(output_values); free(expected_offsets);
        free(level_offsets); free(queue); free(sample_ns); return 3;
    }
    volatile uint64_t warmup_observer = 0;
    for (size_t warmup = 0; warmup < warmup_count; ++warmup) {
        int64_t observed = -1;
        for (size_t repetition = 0; repetition < repetitions; ++repetition)
            observed = run_algorithm(nodes, node_count, root_index, output_values, node_count,
                                     level_offsets, node_count + 1, queue, node_count);
        if (observed != (int64_t)expected_levels ||
            (node_count != 0 && memcmp(output_values, expected_values, node_count * sizeof(*output_values)) != 0) ||
            memcmp(level_offsets, expected_offsets, offset_count * sizeof(*level_offsets)) != 0) {
            fprintf(stderr, "tree traversal changed during warmup\n");
            free(nodes); free(expected_values); free(output_values); free(expected_offsets);
            free(level_offsets); free(queue); free(sample_ns); return 3;
        }
        warmup_observer ^= checksum_outputs(output_values, node_count, level_offsets, offset_count);
    }
    uint64_t total_checksum = 0;
    int64_t observed_levels = (int64_t)expected_levels;
    for (size_t sample = 0; sample < sample_count; ++sample) {
        const clock_t before = clock();
        if (before == (clock_t)-1) {
            fprintf(stderr, "clock() failed before a sample\n");
            free(nodes); free(expected_values); free(output_values); free(expected_offsets);
            free(level_offsets); free(queue); free(sample_ns); return 4;
        }
        for (size_t repetition = 0; repetition < repetitions; ++repetition)
            observed_levels = run_algorithm(nodes, node_count, root_index, output_values, node_count,
                                            level_offsets, node_count + 1, queue, node_count);
        const clock_t after = clock();
        if (after == (clock_t)-1 || after < before || observed_levels != (int64_t)expected_levels ||
            (node_count != 0 && memcmp(output_values, expected_values, node_count * sizeof(*output_values)) != 0) ||
            memcmp(level_offsets, expected_offsets, offset_count * sizeof(*level_offsets)) != 0) {
            fprintf(stderr, "clock() or tree output check failed during a sample\n");
            free(nodes); free(expected_values); free(output_values); free(expected_offsets);
            free(level_offsets); free(queue); free(sample_ns); return 4;
        }
        total_checksum += checksum_outputs(output_values, node_count, level_offsets, offset_count) * repetitions;
        const long double elapsed_ns =
            ((long double)(after - before) * 1000000000.0L) / (long double)CLOCKS_PER_SEC;
        sample_ns[sample] = (uint64_t)(elapsed_ns + 0.5L);
    }
    printf("{\"observed_result\":%" PRId64 ",\"samples_ns\":[", observed_levels);
    for (size_t sample = 0; sample < sample_count; ++sample)
        printf("%s%" PRIu64, sample == 0 ? "" : ",", sample_ns[sample]);
    printf("],\"result_checksum\":%" PRIu64 ",\"timer_resolution_ns\":%.3Lf}\n",
           total_checksum, 1000000000.0L / (long double)CLOCKS_PER_SEC);
    (void)warmup_observer;
    free(nodes); free(expected_values); free(output_values); free(expected_offsets);
    free(level_offsets); free(queue); free(sample_ns);
    return 0;
}
