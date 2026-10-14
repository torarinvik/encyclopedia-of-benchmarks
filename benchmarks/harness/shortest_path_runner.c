/* Portable C11 shortest-path correctness and timing harness. */
#include <ctype.h>
#include <errno.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#ifndef BENCHMARK_FUNCTION
#error "Compile with -DBENCHMARK_FUNCTION=<exported shortest-path symbol>"
#endif
typedef int64_t (*graph_fn)(const int64_t *, size_t, size_t, size_t, int64_t *, uint8_t *);
extern int64_t BENCHMARK_FUNCTION(const int64_t *, size_t, size_t, size_t, int64_t *, uint8_t *);
static graph_fn volatile solve = BENCHMARK_FUNCTION;

typedef struct {
    size_t vertices, edge_count, source;
    int64_t expected;
    int64_t *edges, *snapshot, *distance_storage, *distances, *expected_distances;
    uint8_t *reach_storage, *reachable, *expected_reachable;
} graph_case;

static void release_case(graph_case *data)
{
    free(data->edges);
    free(data->snapshot);
    free(data->distance_storage);
    free(data->expected_distances);
    free(data->reach_storage);
    free(data->expected_reachable);
}

/* Header: V E SOURCE STATUS. Then E triples, then V reach/distance pairs if STATUS=0. */
static int read_case(graph_case *data)
{
    uint64_t vertices, edge_count, source;
    memset(data, 0, sizeof(*data));
    const int fields = scanf("%" SCNu64 " %" SCNu64 " %" SCNu64 " %" SCNd64,
                            &vertices, &edge_count, &source, &data->expected);
    if (fields == EOF && !ferror(stdin)) return 0;
    if (fields != 4 || vertices > 100000 || edge_count > 1000000 || source > SIZE_MAX ||
        vertices > SIZE_MAX / sizeof(int64_t) - 2 ||
        edge_count > SIZE_MAX / (3 * sizeof(int64_t)) ||
        data->expected > 0) return -1;
    data->vertices = (size_t)vertices;
    data->edge_count = (size_t)edge_count;
    data->source = (size_t)source;
    const size_t edge_slots = edge_count == 0 ? 1 : 3 * data->edge_count;
    const size_t vertex_slots = vertices == 0 ? 1 : data->vertices;
    data->edges = malloc(edge_slots * sizeof(*data->edges));
    data->snapshot = malloc(edge_slots * sizeof(*data->snapshot));
    data->distance_storage = malloc((data->vertices + 2) * sizeof(*data->distances));
    data->expected_distances = malloc(vertex_slots * sizeof(*data->expected_distances));
    data->reach_storage = malloc(data->vertices + 2);
    data->expected_reachable = malloc(vertex_slots);
    if (!data->edges || !data->snapshot || !data->distance_storage ||
        !data->expected_distances || !data->reach_storage || !data->expected_reachable) return -1;
    data->distances = data->distance_storage + 1;
    data->reachable = data->reach_storage + 1;
    for (size_t index = 0; index < 3 * data->edge_count; ++index) {
        if (scanf("%" SCNd64, &data->edges[index]) != 1) return -1;
    }
    memcpy(data->snapshot, data->edges, 3 * data->edge_count * sizeof(*data->edges));
    if (data->expected == 0) {
        for (size_t vertex = 0; vertex < data->vertices; ++vertex) {
            int flag;
            if (scanf("%d %" SCNd64, &flag, &data->expected_distances[vertex]) != 2 ||
                (flag != 0 && flag != 1) || (!flag && data->expected_distances[vertex] != 0)) return -1;
            data->expected_reachable[vertex] = (uint8_t)flag;
        }
    }
    return 1;
}

static void poison_outputs(graph_case *data)
{
    data->distance_storage[0] = INT64_MIN + 123;
    data->distance_storage[data->vertices + 1] = INT64_MAX - 123;
    data->reach_storage[0] = 17;
    data->reach_storage[data->vertices + 1] = 29;
    for (size_t vertex = 0; vertex < data->vertices; ++vertex) {
        data->distances[vertex] = INT64_C(123456789123456789);
        data->reachable[vertex] = 255;
    }
}

static int64_t invoke(graph_case *data)
{
    return solve(data->edge_count ? data->edges : NULL, data->vertices, data->edge_count,
                 data->source, data->vertices ? data->distances : NULL,
                 data->vertices ? data->reachable : NULL);
}

static int matches(const graph_case *data, int64_t observed)
{
    if (observed != data->expected) {
        fprintf(stderr, "expected status %" PRId64 ", observed %" PRId64 "\n", data->expected, observed);
        return 0;
    }
    if (data->distance_storage[0] != INT64_MIN + 123 ||
        data->distance_storage[data->vertices + 1] != INT64_MAX - 123 ||
        data->reach_storage[0] != 17 || data->reach_storage[data->vertices + 1] != 29) {
        fprintf(stderr, "output buffer guard changed\n");
        return 0;
    }
    if (memcmp(data->edges, data->snapshot, 3 * data->edge_count * sizeof(*data->edges))) {
        fprintf(stderr, "read-only graph input changed\n");
        return 0;
    }
    if (observed == 0) {
        for (size_t vertex = 0; vertex < data->vertices; ++vertex) {
            if (data->reachable[vertex] != data->expected_reachable[vertex] ||
                data->distances[vertex] != data->expected_distances[vertex]) {
                fprintf(stderr, "distance/reachability mismatch at vertex %zu\n", vertex);
                return 0;
            }
        }
    }
    return 1;
}

static int parse_count(const char *text, uint64_t *value)
{
    char *end;
    if (!*text || *text == '-') return 0;
    errno = 0;
    const unsigned long long parsed = strtoull(text, &end, 10);
    if (errno == ERANGE || *end) return 0;
    *value = (uint64_t)parsed;
    return 1;
}

static int64_t batch(graph_case *data, size_t repetitions, uint64_t *checksum)
{
    int64_t status = 0;
    *checksum = 0;
    for (size_t repetition = 0; repetition < repetitions; ++repetition) {
        status = invoke(data);
        *checksum += (uint64_t)status;
    }
    return status;
}

int main(int argc, char **argv)
{
    if (argc == 2 && strcmp(argv[1], "--check") == 0) {
        uint64_t count = 0;
        for (;;) {
            graph_case data;
            const int read = read_case(&data);
            if (read <= 0) {
                release_case(&data);
                if (read < 0 || count == 0) {
                    fprintf(stderr, "malformed or empty graph corpus\n");
                    return 2;
                }
                printf("{\"cases_checked\":%" PRIu64 "}\n", count);
                return 0;
            }
            poison_outputs(&data);
            const int valid = matches(&data, invoke(&data));
            release_case(&data);
            if (!valid) {
                fprintf(stderr, "graph case %" PRIu64 " failed\n", count);
                return 3;
            }
            ++count;
        }
    }
    uint64_t samples, warmups, repetitions;
    if (argc != 4 || !parse_count(argv[1], &samples) || !parse_count(argv[2], &warmups) ||
        !parse_count(argv[3], &repetitions) || samples == 0 || samples > 10000 ||
        warmups > 100000 || repetitions == 0 || repetitions > 1000000) {
        fprintf(stderr, "usage: shortest_path_runner SAMPLES WARMUPS REPETITIONS | --check\n");
        return 2;
    }
    graph_case data;
    const int read = read_case(&data);
    if (read != 1) {
        release_case(&data);
        fprintf(stderr, "expected one graph case on stdin\n");
        return 2;
    }
    int extra;
    while ((extra = getchar()) != EOF) {
        if (!isspace((unsigned char)extra)) {
            release_case(&data);
            fprintf(stderr, "unexpected trailing graph input\n");
            return 2;
        }
    }
    uint64_t *sample_ns = malloc((size_t)samples * sizeof(*sample_ns));
    if (!sample_ns) { release_case(&data); return 2; }
    poison_outputs(&data);
    if (!matches(&data, invoke(&data))) { free(sample_ns); release_case(&data); return 3; }
    volatile uint64_t warmup_observer = 0;
    for (size_t warmup = 0; warmup < (size_t)warmups; ++warmup) {
        uint64_t checksum;
        poison_outputs(&data);
        const int64_t status = batch(&data, (size_t)repetitions, &checksum);
        warmup_observer ^= checksum;
        if (!matches(&data, status)) { free(sample_ns); release_case(&data); return 3; }
    }
    uint64_t total_checksum = 0;
    int64_t observed = 0;
    for (size_t sample = 0; sample < (size_t)samples; ++sample) {
        poison_outputs(&data);
        const clock_t start = clock();
        if (start == (clock_t)-1) { free(sample_ns); release_case(&data); return 4; }
        uint64_t checksum;
        observed = batch(&data, (size_t)repetitions, &checksum);
        const clock_t finish = clock();
        if (finish == (clock_t)-1 || finish < start) { free(sample_ns); release_case(&data); return 4; }
        if (!matches(&data, observed)) { free(sample_ns); release_case(&data); return 3; }
        total_checksum += checksum;
        const long double elapsed = (long double)(finish - start) * 1000000000.0L / CLOCKS_PER_SEC;
        sample_ns[sample] = (uint64_t)(elapsed + 0.5L);
    }
    printf("{\"observed_result\":%" PRId64 ",\"distances\":", observed);
    if (observed == 0) {
        printf("[");
        for (size_t vertex = 0; vertex < data.vertices; ++vertex)
            printf("%s%" PRId64, vertex ? "," : "", data.distances[vertex]);
        printf("],\"reachable\":[");
        for (size_t vertex = 0; vertex < data.vertices; ++vertex) {
            printf("%s%u", vertex ? "," : "", (unsigned)data.reachable[vertex]);
            total_checksum = (total_checksum ^ (uint64_t)data.distances[vertex]) * UINT64_C(1099511628211);
            total_checksum = (total_checksum ^ data.reachable[vertex]) * UINT64_C(1099511628211);
        }
        printf("]");
    } else printf("null,\"reachable\":null");
    printf(",\"samples_ns\":[");
    for (size_t sample = 0; sample < (size_t)samples; ++sample)
        printf("%s%" PRIu64, sample ? "," : "", sample_ns[sample]);
    printf("],\"result_checksum\":%" PRIu64 ",\"timer_resolution_ns\":%.3Lf}\n",
           total_checksum, 1000000000.0L / CLOCKS_PER_SEC);
    (void)warmup_observer;
    free(sample_ns);
    release_case(&data);
    return 0;
}
