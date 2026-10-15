/* Timed runner for range-sum queries over indexed binary trees. */
#include <errno.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#ifndef BENCHMARK_FUNCTION
#error "Compile with -DBENCHMARK_FUNCTION=<exported function symbol>"
#endif

#define MAX_NODE_COUNT 1023
typedef int64_t (*tree_range_sum_fn)(const int64_t *, size_t, int64_t, int64_t, int64_t);
extern int64_t BENCHMARK_FUNCTION(const int64_t *, size_t, int64_t, int64_t, int64_t);
static tree_range_sum_fn volatile run_algorithm = BENCHMARK_FUNCTION;

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

static int64_t run_batch(const int64_t *nodes, size_t node_count, int64_t root_index,
                         int64_t low, int64_t high, size_t repetitions, uint64_t *checksum)
{
    int64_t result = 0;
    uint64_t local_checksum = 0;
    for (size_t repetition = 0; repetition < repetitions; ++repetition) {
        result = run_algorithm(nodes, node_count, root_index, low, high);
        local_checksum += (uint64_t)result;
    }
    *checksum = local_checksum;
    return result;
}

int main(int argc, char **argv)
{
    uint64_t samples_arg, warmups_arg, repetitions_arg, node_count_arg;
    int64_t expected, root_index, low, high;
    if (argc != 5 || !parse_i64(argv[1], &expected) ||
        !parse_u64(argv[2], &samples_arg) || !parse_u64(argv[3], &warmups_arg) ||
        !parse_u64(argv[4], &repetitions_arg) ||
        scanf("%" SCNu64 " %" SCNd64 " %" SCNd64 " %" SCNd64,
              &node_count_arg, &root_index, &low, &high) != 4 ||
        node_count_arg > MAX_NODE_COUNT || samples_arg == 0 || samples_arg > 10000 ||
        warmups_arg > 100000 || repetitions_arg == 0 || repetitions_arg > 1000000000) {
        fprintf(stderr, "invalid tree runner header or timing settings\n");
        return 2;
    }
    const size_t node_count = (size_t)node_count_arg;
    const size_t sample_count = (size_t)samples_arg;
    const size_t warmup_count = (size_t)warmups_arg;
    const size_t repetitions = (size_t)repetitions_arg;
    int64_t *nodes = node_count == 0 ? NULL : malloc(3 * node_count * sizeof(*nodes));
    uint64_t *sample_ns = malloc(sample_count * sizeof(*sample_ns));
    if ((node_count != 0 && nodes == NULL) || sample_ns == NULL) {
        fprintf(stderr, "unable to allocate tree runner buffers\n");
        free(nodes); free(sample_ns); return 2;
    }
    for (size_t index = 0; index < 3 * node_count; ++index) {
        if (scanf("%" SCNd64, &nodes[index]) != 1) {
            fprintf(stderr, "truncated tree node table\n");
            free(nodes); free(sample_ns); return 2;
        }
    }
    char extra;
    if (scanf(" %c", &extra) == 1 || ferror(stdin)) {
        fprintf(stderr, "unexpected trailing tree workload input\n");
        free(nodes); free(sample_ns); return 2;
    }
    if (run_algorithm(nodes, node_count, root_index, low, high) != expected) {
        fprintf(stderr, "correctness mismatch for tree input\n");
        free(nodes); free(sample_ns); return 3;
    }
    volatile uint64_t warmup_observer = 0;
    for (size_t warmup = 0; warmup < warmup_count; ++warmup) {
        uint64_t checksum = 0;
        if (run_batch(nodes, node_count, root_index, low, high, repetitions, &checksum) != expected) {
            fprintf(stderr, "algorithm result changed during warmup\n");
            free(nodes); free(sample_ns); return 3;
        }
        warmup_observer ^= checksum;
    }
    uint64_t total_checksum = 0;
    int64_t observed_result = expected;
    for (size_t sample = 0; sample < sample_count; ++sample) {
        const clock_t start = clock();
        if (start == (clock_t)-1) {
            fprintf(stderr, "clock() failed before a sample\n");
            free(nodes); free(sample_ns); return 4;
        }
        uint64_t checksum = 0;
        observed_result = run_batch(nodes, node_count, root_index, low, high,
                                    repetitions, &checksum);
        const clock_t finish = clock();
        if (finish == (clock_t)-1 || finish < start || observed_result != expected) {
            fprintf(stderr, "clock() or result check failed during a sample\n");
            free(nodes); free(sample_ns); return 4;
        }
        total_checksum += checksum;
        const long double elapsed_ns =
            ((long double)(finish - start) * 1000000000.0L) / (long double)CLOCKS_PER_SEC;
        sample_ns[sample] = (uint64_t)(elapsed_ns + 0.5L);
    }
    printf("{\"observed_result\":%" PRId64 ",\"samples_ns\":[", observed_result);
    for (size_t sample = 0; sample < sample_count; ++sample)
        printf("%s%" PRIu64, sample == 0 ? "" : ",", sample_ns[sample]);
    printf("],\"result_checksum\":%" PRIu64 ",\"timer_resolution_ns\":%.3Lf}\n",
           total_checksum, 1000000000.0L / (long double)CLOCKS_PER_SEC);
    (void)warmup_observer;
    free(nodes);
    free(sample_ns);
    return 0;
}
