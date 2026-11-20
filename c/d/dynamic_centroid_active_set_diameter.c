#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define ACTIVE_DIAMETER_MAX_N 32
#define ACTIVE_DIAMETER_MAX_OPERATIONS 64
#define ACTIVE_DIAMETER_MAX_LEVELS 6
#define ACTIVE_DIAMETER_MAX_PARSEABLE_LENGTH 98

typedef struct {
    int n;
    int adjacency[ACTIVE_DIAMETER_MAX_N * ACTIVE_DIAMETER_MAX_N];
    int blocked[ACTIVE_DIAMETER_MAX_N];
    int subtree_size[ACTIVE_DIAMETER_MAX_N];
    int record_count[ACTIVE_DIAMETER_MAX_N];
    int record_centroid[ACTIVE_DIAMETER_MAX_N * ACTIVE_DIAMETER_MAX_LEVELS];
    int record_branch[ACTIVE_DIAMETER_MAX_N * ACTIVE_DIAMETER_MAX_LEVELS];
    int record_distance[ACTIVE_DIAMETER_MAX_N * ACTIVE_DIAMETER_MAX_LEVELS];
} ActiveDiameterContext;

static int component_size(ActiveDiameterContext *context, int vertex, int parent) {
    int total = 1;
    context->subtree_size[vertex] = 1;
    for (int neighbor = 0; neighbor < context->n; ++neighbor) {
        if (context->adjacency[vertex * context->n + neighbor]
                && neighbor != parent && !context->blocked[neighbor]) {
            total += component_size(context, neighbor, vertex);
        }
    }
    context->subtree_size[vertex] = total;
    return total;
}

static int choose_centroid(ActiveDiameterContext *context, int vertex,
                           int parent, int total) {
    for (int neighbor = 0; neighbor < context->n; ++neighbor) {
        if (context->adjacency[vertex * context->n + neighbor]
                && neighbor != parent && !context->blocked[neighbor]
                && context->subtree_size[neighbor] > total / 2) {
            return choose_centroid(context, neighbor, vertex, total);
        }
    }
    return vertex;
}

static void record_component(ActiveDiameterContext *context, int centroid,
                             int vertex, int parent, int distance, int branch,
                             int level) {
    if (level >= ACTIVE_DIAMETER_MAX_LEVELS) return;
    const int index = vertex * ACTIVE_DIAMETER_MAX_LEVELS + level;
    context->record_centroid[index] = centroid;
    context->record_branch[index] = vertex == centroid ? context->n : branch;
    context->record_distance[index] = distance;
    context->record_count[vertex] = level + 1;
    for (int neighbor = 0; neighbor < context->n; ++neighbor) {
        if (context->adjacency[vertex * context->n + neighbor]
                && neighbor != parent && !context->blocked[neighbor]) {
            const int next_branch = vertex == centroid ? neighbor : branch;
            record_component(context, centroid, neighbor, vertex, distance + 1,
                             next_branch, level);
        }
    }
}

static void build_centroid_records(ActiveDiameterContext *context, int entry,
                                   int level) {
    if (level >= ACTIVE_DIAMETER_MAX_LEVELS) return;
    const int total = component_size(context, entry, -1);
    const int centroid = choose_centroid(context, entry, -1, total);
    record_component(context, centroid, centroid, -1, 0, context->n, level);
    context->blocked[centroid] = 1;
    for (int neighbor = 0; neighbor < context->n; ++neighbor) {
        if (context->adjacency[centroid * context->n + neighbor]
                && !context->blocked[neighbor]) {
            build_centroid_records(context, neighbor, level + 1);
        }
    }
}

static void recompute_branch(ActiveDiameterContext *context, int centroid,
                             int branch, const int *active, int *best) {
    best[centroid * (context->n + 1) + branch] = -1;
    for (int vertex = 0; vertex < context->n; ++vertex) {
        if (!active[vertex]) continue;
        for (int record = 0; record < context->record_count[vertex]; ++record) {
            const int index = vertex * ACTIVE_DIAMETER_MAX_LEVELS + record;
            if (context->record_centroid[index] == centroid
                    && context->record_branch[index] == branch) {
                int *bucket = &best[centroid * (context->n + 1) + branch];
                if (context->record_distance[index] > *bucket)
                    *bucket = context->record_distance[index];
            }
        }
    }
}

static int active_diameter(int n, const int *best) {
    int answer = 0;
    for (int centroid = 0; centroid < n; ++centroid) {
        int first = -1, second = -1;
        for (int branch = 0; branch <= n; ++branch) {
            const int distance = best[centroid * (n + 1) + branch];
            if (distance > first) {
                second = first;
                first = distance;
            } else if (distance > second) {
                second = distance;
            }
        }
        if (second >= 0 && first + second > answer) answer = first + second;
    }
    return answer;
}

int64_t dynamic_centroid_active_set_diameter(const int64_t *input, size_t length) {
    if (input == NULL || length < 2
            || length > ACTIVE_DIAMETER_MAX_PARSEABLE_LENGTH) return -1;
    const int64_t n_value = input[0];
    const int64_t operation_count_value = input[1];
    if (n_value < 1 || n_value > ACTIVE_DIAMETER_MAX_N
            || operation_count_value < 0
            || operation_count_value > ACTIVE_DIAMETER_MAX_OPERATIONS) return -1;
    const int n = (int)n_value;
    const int operation_count = (int)operation_count_value;
    if (length != (size_t)(n + 1 + operation_count)) return -1;

    ActiveDiameterContext context = {0};
    context.n = n;
    for (int vertex = 1; vertex < n; ++vertex) {
        const int64_t parent_value = input[vertex + 1];
        if (parent_value < 0 || parent_value >= vertex) return -1;
        const int parent = (int)parent_value;
        context.adjacency[parent * n + vertex] = 1;
        context.adjacency[vertex * n + parent] = 1;
    }
    for (int index = n + 1; index < n + 1 + operation_count; ++index) {
        if (input[index] != -1 && (input[index] < 0 || input[index] >= n)) return -1;
    }

    build_centroid_records(&context, 0, 0);
    int best[ACTIVE_DIAMETER_MAX_N * (ACTIVE_DIAMETER_MAX_N + 1)];
    int active[ACTIVE_DIAMETER_MAX_N] = {0};
    for (int centroid = 0; centroid < n; ++centroid)
        for (int branch = 0; branch <= n; ++branch)
            best[centroid * (n + 1) + branch] = -1;

    int64_t checksum = 0;
    int query_number = 0;
    for (int offset = 0; offset < operation_count; ++offset) {
        const int64_t operation = input[n + 1 + offset];
        if (operation == -1) {
            ++query_number;
            checksum += (int64_t)query_number * (active_diameter(n, best) + 1);
            continue;
        }
        const int vertex = (int)operation;
        active[vertex] = !active[vertex];
        for (int record = 0; record < context.record_count[vertex]; ++record) {
            const int index = vertex * ACTIVE_DIAMETER_MAX_LEVELS + record;
            const int centroid = context.record_centroid[index];
            const int branch = context.record_branch[index];
            const int distance = context.record_distance[index];
            int *bucket = &best[centroid * (n + 1) + branch];
            if (active[vertex]) {
                if (distance > *bucket) *bucket = distance;
            } else if (*bucket == distance) {
                recompute_branch(&context, centroid, branch, active, best);
            }
        }
    }
    return checksum;
}
