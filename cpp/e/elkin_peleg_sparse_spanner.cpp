#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <queue>
#include <tuple>
#include <utility>
#include <vector>

namespace {
constexpr int kMaxN = 20;
constexpr int kMaxM = kMaxN * (kMaxN - 1) / 2;
constexpr std::size_t kMaxInput = 2 + 2 * kMaxM + 1;
constexpr int kInf = 1000;

struct Cluster {
    int center = -1;
    int radius = 0;
    std::vector<int> members;
    std::vector<std::uint8_t> tree;
};

using Graph = std::vector<std::vector<int>>;
using Distances = std::vector<std::vector<int>>;
using EdgeIndex = std::vector<std::vector<int>>;
using Flags = std::vector<std::uint8_t>;

std::vector<int> bfs_distances(const Graph& graph, int source) {
    std::vector<int> distance(graph.size(), kInf);
    std::queue<int> pending;
    distance[source] = 0;
    pending.push(source);
    while (!pending.empty()) {
        const int vertex = pending.front();
        pending.pop();
        for (const int neighbor : graph[vertex]) {
            if (distance[neighbor] == kInf) {
                distance[neighbor] = distance[vertex] + 1;
                pending.push(neighbor);
            }
        }
    }
    return distance;
}

Distances all_distances(const Graph& graph) {
    Distances result(graph.size());
    for (int source = 0; source < static_cast<int>(graph.size()); ++source)
        result[source] = bfs_distances(graph, source);
    return result;
}

int edge_id(int a, int b, const EdgeIndex& index) {
    return index[a][b];
}

bool cluster_before(const Cluster& left, const Cluster& right) {
    return std::tie(left.center, left.members) < std::tie(right.center, right.members);
}

std::pair<Flags, int> bfs_tree(const Graph& graph, const EdgeIndex& index,
                               const std::vector<std::uint8_t>& allowed, int root,
                               int edge_count) {
    const int n = static_cast<int>(graph.size());
    std::vector<int> distance(n, kInf), parent(n, -1), pending;
    distance[root] = 0;
    pending.push_back(root);
    for (std::size_t head = 0; head < pending.size(); ++head) {
        const int vertex = pending[head];
        for (const int neighbor : graph[vertex]) {
            if (allowed[neighbor] && distance[neighbor] == kInf) {
                distance[neighbor] = distance[vertex] + 1;
                parent[neighbor] = vertex;
                pending.push_back(neighbor);
            }
        }
    }
    Flags tree(edge_count, 0);
    int radius = 0;
    for (int vertex = 0; vertex < n; ++vertex) {
        if (!allowed[vertex]) continue;
        radius = std::max(radius, distance[vertex]);
        if (vertex != root) tree[edge_id(vertex, parent[vertex], index)] = 1;
    }
    return {std::move(tree), radius};
}

int set_distance(const Cluster& left, const Cluster& right, const Distances& distance) {
    int best = kInf;
    for (const int u : left.members)
        for (const int v : right.members)
            best = std::min(best, distance[u][v]);
    return best;
}

Flags connector(const Graph& graph, const EdgeIndex& index,
                const Cluster& left, const Cluster& right, int edge_count) {
    int best_distance = kInf;
    std::vector<int> best_path;
    for (const int source : left.members) {
        std::vector<int> distance(graph.size(), kInf), parent(graph.size(), -1), pending;
        distance[source] = 0;
        pending.push_back(source);
        for (std::size_t head = 0; head < pending.size(); ++head) {
            const int vertex = pending[head];
            for (const int neighbor : graph[vertex]) {
                if (distance[neighbor] == kInf) {
                    distance[neighbor] = distance[vertex] + 1;
                    parent[neighbor] = vertex;
                    pending.push_back(neighbor);
                }
            }
        }
        for (const int target : right.members) {
            if (distance[target] > best_distance) continue;
            std::vector<int> path;
            for (int vertex = target; vertex >= 0; vertex = parent[vertex]) {
                path.push_back(vertex);
                if (vertex == source) break;
            }
            if (path.empty() || path.back() != source) continue;
            std::reverse(path.begin(), path.end());
            if (distance[target] < best_distance ||
                (distance[target] == best_distance &&
                 (best_path.empty() || std::lexicographical_compare(
                     path.begin(), path.end(), best_path.begin(), best_path.end())))) {
                best_distance = distance[target];
                best_path = std::move(path);
            }
        }
    }
    Flags result(edge_count, 0);
    for (std::size_t i = 1; i < best_path.size(); ++i)
        result[edge_id(best_path[i - 1], best_path[i], index)] = 1;
    return result;
}

std::pair<std::vector<Cluster>, Flags> down_part(
    int n, const Graph& graph, const EdgeIndex& index, int edge_count) {
    std::vector<std::uint8_t> uncovered(n, 1);
    std::vector<Cluster> ground;
    Flags chosen(edge_count, 0);
    for (;;) {
        const auto root_it = std::find(uncovered.begin(), uncovered.end(), 1);
        if (root_it == uncovered.end()) break;
        const int root = static_cast<int>(root_it - uncovered.begin());
        std::vector<std::uint8_t> members(n, 0);
        members[root] = 1;
        int size = 1;
        for (;;) {
            auto shell = members;
            for (int vertex = 0; vertex < n; ++vertex)
                if (members[vertex])
                    for (const int neighbor : graph[vertex])
                        if (uncovered[neighbor]) shell[neighbor] = 1;
            const int shell_size = static_cast<int>(std::count(shell.begin(), shell.end(), 1));
            const int size4 = size * size * size * size;
            const int shell4 = shell_size * shell_size * shell_size * shell_size;
            if (shell_size == size || shell4 < n * size4) break;
            members.swap(shell);
            size = shell_size;
        }
        auto shell = members;
        for (int vertex = 0; vertex < n; ++vertex)
            if (members[vertex])
                for (const int neighbor : graph[vertex])
                    if (uncovered[neighbor]) shell[neighbor] = 1;

        Cluster cluster;
        cluster.center = root;
        for (int v = 0; v < n; ++v) if (members[v]) cluster.members.push_back(v);
        auto [tree, radius] = bfs_tree(graph, index, members, root, edge_count);
        cluster.tree = std::move(tree);
        cluster.radius = radius;
        auto [shell_tree, ignored_radius] = bfs_tree(graph, index, shell, root, edge_count);
        (void)ignored_radius;
        for (int e = 0; e < edge_count; ++e) chosen[e] |= shell_tree[e];
        ground.push_back(std::move(cluster));
        for (int v = 0; v < n; ++v) if (members[v]) uncovered[v] = 0;
    }
    return {std::move(ground), std::move(chosen)};
}

std::pair<std::vector<Cluster>, Flags> supercluster(
    const Graph& graph, const EdgeIndex& index, const Distances& distance,
    const std::vector<Cluster>& clusters, int sigma, int delta, int edge_count) {
    std::vector<std::uint8_t> active(clusters.size(), 1);
    std::vector<Cluster> merged;
    Flags chosen(edge_count, 0);
    for (;;) {
        int center_id = -1;
        std::vector<std::vector<int>> neighborhoods(clusters.size());
        for (int candidate = 0; candidate < static_cast<int>(clusters.size()); ++candidate) {
            if (!active[candidate]) continue;
            for (int other = 0; other < static_cast<int>(clusters.size()); ++other)
                if (active[other] && set_distance(clusters[candidate], clusters[other], distance) <= delta)
                    neighborhoods[candidate].push_back(other);
            if (static_cast<int>(neighborhoods[candidate].size()) >= sigma &&
                (center_id < 0 || cluster_before(clusters[candidate], clusters[center_id])))
                center_id = candidate;
        }
        if (center_id < 0) break;
        Cluster cluster;
        cluster.center = clusters[center_id].center;
        cluster.tree.assign(edge_count, 0);
        std::vector<std::uint8_t> members(graph.size(), 0);
        for (const int other : neighborhoods[center_id]) {
            active[other] = 0;
            for (int v = 0; v < static_cast<int>(graph.size()); ++v)
                members[v] |= static_cast<std::uint8_t>(std::binary_search(
                    clusters[other].members.begin(), clusters[other].members.end(), v));
            for (int e = 0; e < edge_count; ++e) cluster.tree[e] |= clusters[other].tree[e];
            if (other != center_id) {
                const Flags path = connector(graph, index, clusters[center_id], clusters[other], edge_count);
                for (int e = 0; e < edge_count; ++e) cluster.tree[e] |= path[e];
            }
        }
        for (int v = 0; v < static_cast<int>(graph.size()); ++v) if (members[v]) cluster.members.push_back(v);
        for (int e = 0; e < edge_count; ++e) chosen[e] |= cluster.tree[e];
        merged.push_back(std::move(cluster));
    }
    std::vector<int> remaining;
    for (int i = 0; i < static_cast<int>(clusters.size()); ++i) if (active[i]) remaining.push_back(i);
    std::sort(remaining.begin(), remaining.end(), [&](int a, int b) {
        return cluster_before(clusters[a], clusters[b]);
    });
    for (std::size_t i = 0; i < remaining.size(); ++i)
        for (std::size_t j = i + 1; j < remaining.size(); ++j) {
            const Cluster& left = clusters[remaining[i]];
            const Cluster& right = clusters[remaining[j]];
            if (set_distance(left, right, distance) <= delta) {
                const Flags path = connector(graph, index, left, right, edge_count);
                for (int e = 0; e < edge_count; ++e) chosen[e] |= path[e];
            }
        }
    return {std::move(merged), std::move(chosen)};
}

int ceil_fourth_root(int value) {
    int root = 1;
    while (root * root * root * root < value) ++root;
    return root;
}
}  // namespace

extern "C" std::int64_t elkin_peleg_sparse_spanner(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > kMaxInput) return -1;
    const std::int64_t n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > kMaxN || m64 < 0 || m64 > kMaxM ||
        length != 2 + 2 * static_cast<std::size_t>(m64)) return -1;
    const int n = static_cast<int>(n64), m = static_cast<int>(m64);
    Graph graph(n);
    EdgeIndex index(n, std::vector<int>(n, -1));
    for (int edge = 0; edge < m; ++edge) {
        const std::int64_t u64 = input[2 + 2 * edge], v64 = input[3 + 2 * edge];
        if (u64 < 0 || v64 <= u64 || v64 >= n64) return -1;
        const int u = static_cast<int>(u64), v = static_cast<int>(v64);
        if (index[u][v] >= 0) return -1;
        index[u][v] = index[v][u] = edge;
        graph[u].push_back(v);
        graph[v].push_back(u);
    }
    for (auto& neighbors : graph) std::sort(neighbors.begin(), neighbors.end());
    if (output == nullptr || capacity < static_cast<std::size_t>(m)) return -2;

    const Distances distance = all_distances(graph);
    auto [ground, chosen] = down_part(n, graph, index, m);
    std::vector<Cluster> level;
    for (const Cluster& cluster : ground) if (cluster.radius == 1) level.push_back(cluster);
    auto [superclusters, additions] = supercluster(
        graph, index, distance, level, ceil_fourth_root(n), 16, m);
    for (int edge = 0; edge < m; ++edge) chosen[edge] |= additions[edge];

    std::vector<Cluster> final_clusters = std::move(superclusters);
    for (const Cluster& cluster : ground)
        if (cluster.radius == 2 || cluster.radius == 3) final_clusters.push_back(cluster);
    std::sort(final_clusters.begin(), final_clusters.end(), cluster_before);
    for (std::size_t i = 0; i < final_clusters.size(); ++i)
        for (std::size_t j = i + 1; j < final_clusters.size(); ++j)
            if (set_distance(final_clusters[i], final_clusters[j], distance) <= 128) {
                const Flags path = connector(graph, index, final_clusters[i], final_clusters[j], m);
                for (int edge = 0; edge < m; ++edge) chosen[edge] |= path[edge];
            }
    for (int edge = 0; edge < m; ++edge) output[edge] = chosen[edge];
    return m;
}
