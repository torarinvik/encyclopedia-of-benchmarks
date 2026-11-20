#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxN = 32;
constexpr int kMaxOperations = 64;
constexpr int kMaxLevels = 6;
constexpr std::size_t kMaxParseableLength = 98;

struct Context {
    int n = 0;
    int adjacency[kMaxN * kMaxN]{};
    int blocked[kMaxN]{};
    int subtree_size[kMaxN]{};
    int record_count[kMaxN]{};
    int record_centroid[kMaxN * kMaxLevels]{};
    int record_branch[kMaxN * kMaxLevels]{};
    int record_distance[kMaxN * kMaxLevels]{};
};

int component_size(Context& context, int vertex, int parent) {
    int total = 1;
    for (int neighbor = 0; neighbor < context.n; ++neighbor) {
        if (context.adjacency[vertex * context.n + neighbor]
                && neighbor != parent && !context.blocked[neighbor]) {
            total += component_size(context, neighbor, vertex);
        }
    }
    context.subtree_size[vertex] = total;
    return total;
}

int choose_centroid(Context& context, int vertex, int parent, int total) {
    for (int neighbor = 0; neighbor < context.n; ++neighbor) {
        if (context.adjacency[vertex * context.n + neighbor]
                && neighbor != parent && !context.blocked[neighbor]
                && context.subtree_size[neighbor] > total / 2) {
            return choose_centroid(context, neighbor, vertex, total);
        }
    }
    return vertex;
}

void record_component(Context& context, int centroid, int vertex, int parent,
                      int distance, int branch, int level) {
    if (level >= kMaxLevels) return;
    const int index = vertex * kMaxLevels + level;
    context.record_centroid[index] = centroid;
    context.record_branch[index] = vertex == centroid ? context.n : branch;
    context.record_distance[index] = distance;
    context.record_count[vertex] = level + 1;
    for (int neighbor = 0; neighbor < context.n; ++neighbor) {
        if (context.adjacency[vertex * context.n + neighbor]
                && neighbor != parent && !context.blocked[neighbor]) {
            const int next_branch = vertex == centroid ? neighbor : branch;
            record_component(context, centroid, neighbor, vertex, distance + 1,
                             next_branch, level);
        }
    }
}

void build_centroid_records(Context& context, int entry, int level) {
    if (level >= kMaxLevels) return;
    const int total = component_size(context, entry, -1);
    const int centroid = choose_centroid(context, entry, -1, total);
    record_component(context, centroid, centroid, -1, 0, context.n, level);
    context.blocked[centroid] = 1;
    for (int neighbor = 0; neighbor < context.n; ++neighbor) {
        if (context.adjacency[centroid * context.n + neighbor]
                && !context.blocked[neighbor]) {
            build_centroid_records(context, neighbor, level + 1);
        }
    }
}

void recompute_branch(Context& context, int centroid, int branch,
                      const int* active, int* best) {
    best[centroid * (context.n + 1) + branch] = -1;
    for (int vertex = 0; vertex < context.n; ++vertex) {
        if (!active[vertex]) continue;
        for (int record = 0; record < context.record_count[vertex]; ++record) {
            const int index = vertex * kMaxLevels + record;
            if (context.record_centroid[index] == centroid
                    && context.record_branch[index] == branch) {
                int& bucket = best[centroid * (context.n + 1) + branch];
                if (context.record_distance[index] > bucket)
                    bucket = context.record_distance[index];
            }
        }
    }
}

int active_diameter(int n, const int* best) {
    int answer = 0;
    for (int centroid = 0; centroid < n; ++centroid) {
        int first = -1;
        int second = -1;
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
}  // namespace

extern "C" std::int64_t dynamic_centroid_active_set_diameter(
    const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 2 || length > kMaxParseableLength) return -1;
    const std::int64_t n_value = input[0];
    const std::int64_t q_value = input[1];
    if (n_value < 1 || n_value > kMaxN
            || q_value < 0 || q_value > kMaxOperations) return -1;
    const int n = static_cast<int>(n_value);
    const int q = static_cast<int>(q_value);
    if (length != static_cast<std::size_t>(n + 1 + q)) return -1;

    Context context{};
    context.n = n;
    for (int vertex = 1; vertex < n; ++vertex) {
        const std::int64_t parent_value = input[vertex + 1];
        if (parent_value < 0 || parent_value >= vertex) return -1;
        const int parent = static_cast<int>(parent_value);
        context.adjacency[parent * n + vertex] = 1;
        context.adjacency[vertex * n + parent] = 1;
    }
    for (int index = n + 1; index < n + 1 + q; ++index) {
        const std::int64_t operation = input[index];
        if (operation != -1 && (operation < 0 || operation >= n)) return -1;
    }

    build_centroid_records(context, 0, 0);
    int best[kMaxN * (kMaxN + 1)];
    int active[kMaxN]{};
    for (int centroid = 0; centroid < n; ++centroid)
        for (int branch = 0; branch <= n; ++branch)
            best[centroid * (n + 1) + branch] = -1;

    std::int64_t checksum = 0;
    int query_number = 0;
    for (int offset = 0; offset < q; ++offset) {
        const std::int64_t operation = input[n + 1 + offset];
        if (operation == -1) {
            ++query_number;
            checksum += static_cast<std::int64_t>(query_number)
                * (active_diameter(n, best) + 1);
            continue;
        }
        const int vertex = static_cast<int>(operation);
        active[vertex] = !active[vertex];
        for (int record = 0; record < context.record_count[vertex]; ++record) {
            const int index = vertex * kMaxLevels + record;
            const int centroid = context.record_centroid[index];
            const int branch = context.record_branch[index];
            const int distance = context.record_distance[index];
            int& bucket = best[centroid * (n + 1) + branch];
            if (active[vertex]) {
                if (distance > bucket) bucket = distance;
            } else if (bucket == distance) {
                recompute_branch(context, centroid, branch, active, best);
            }
        }
    }
    return checksum;
}
