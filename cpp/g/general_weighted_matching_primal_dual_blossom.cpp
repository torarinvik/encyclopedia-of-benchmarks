/* Maximum-weight matching in a non-bipartite graph. */
#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <limits>

namespace {
constexpr int kMaxN = 64;
constexpr int kIds = 2 * kMaxN;
constexpr int kSlots = kIds + 1;
constexpr std::int64_t kInfinity = std::numeric_limits<std::int64_t>::max();

struct BlossomSearch {
    int n = 0, nodes = 0, epoch = 0;
    std::int64_t weight[kSlots][kSlots]{};
    std::int64_t dual[kSlots]{};
    std::int16_t endpoint_a[kSlots][kSlots]{}, endpoint_b[kSlots][kSlots]{};
    std::int16_t mate[kSlots]{}, slack_from[kSlots]{}, top[kSlots]{}, parent[kSlots]{};
    std::int16_t label[kSlots]{};
    int visit[kSlots]{};
    std::int16_t members[kSlots][kSlots]{}, member_count[kSlots]{};
    std::int16_t child_of[kSlots][kMaxN + 1]{};
    std::array<int, kMaxN> queue{};
    std::array<bool, kMaxN + 1> queued{};
    int head = 0, tail = 0, count = 0;

    std::int64_t reduced_cost(int a, int b) const {
        return dual[endpoint_a[a][b]] + dual[endpoint_b[a][b]] - 2 * weight[a][b];
    }

    void enqueue_leaf(int v) {
        if (v < 1 || v > n || queued[v]) return;
        queue[tail] = v;
        tail = (tail + 1) % n;
        ++count;
        queued[v] = true;
    }

    void enqueue_members(int x) {
        if (x <= n) {
            enqueue_leaf(x);
            return;
        }
        for (int i = 0; i < member_count[x]; ++i) enqueue_members(members[x][i]);
    }

    void set_top(int x, int b) {
        top[x] = static_cast<std::int16_t>(b);
        if (x > n)
            for (int i = 0; i < member_count[x]; ++i) set_top(members[x][i], b);
    }

    void refresh_slack(int x) {
        slack_from[x] = 0;
        for (int u = 1; u <= n; ++u) {
            if (weight[u][x] == 0 || top[u] == x || label[top[u]] != 0) continue;
            const int old = slack_from[x];
            if (old == 0 || reduced_cost(u, x) < reduced_cost(old, x))
                slack_from[x] = static_cast<std::int16_t>(u);
        }
    }

    int cycle_position(int b, int child) {
        int pos = 0;
        while (pos < member_count[b] && members[b][pos] != child) ++pos;
        if (pos >= member_count[b]) return 0;
        if (pos & 1) {
            std::reverse(members[b] + 1, members[b] + member_count[b]);
            pos = member_count[b] - pos;
        }
        return pos;
    }

    void rotate_cycle(int b, int start) {
        std::array<std::int16_t, kSlots> rotated{};
        const int size = member_count[b];
        for (int i = 0; i < size; ++i) rotated[i] = members[b][(i + start) % size];
        for (int i = 0; i < size; ++i) members[b][i] = rotated[i];
    }

    void set_pair(int u, int v) {
        mate[u] = endpoint_b[u][v];
        if (u <= n) return;
        const int entry_leaf = endpoint_a[u][v];
        const int entry_child = child_of[u][entry_leaf];
        const int pos = cycle_position(u, entry_child);
        for (int i = 0; i < pos; ++i)
            set_pair(members[u][i], members[u][i ^ 1]);
        set_pair(entry_child, v);
        rotate_cycle(u, pos);
    }

    void augment(int u, int v) {
        for (;;) {
            const int next = top[mate[u]];
            set_pair(u, v);
            if (next == 0) return;
            const int prior = top[parent[next]];
            set_pair(next, prior);
            u = prior;
            v = next;
        }
    }

    int common_base(int u, int v) {
        ++epoch;
        while (u != 0 || v != 0) {
            if (u != 0) {
                if (visit[u] == epoch) return u;
                visit[u] = epoch;
                u = top[mate[u]];
                if (u != 0) u = top[parent[u]];
            }
            std::swap(u, v);
        }
        return 0;
    }

    void add_member(int b, int x) {
        members[b][member_count[b]++] = static_cast<std::int16_t>(x);
    }

    void contract(int u, int base, int v) {
        int b = n + 1;
        while (b <= nodes && top[b] != 0) ++b;
        if (b > nodes) ++nodes;

        dual[b] = 0;
        label[b] = 0;
        mate[b] = mate[base];
        member_count[b] = 0;
        add_member(b, base);
        for (int x = u, y; x != base; x = top[parent[y]]) {
            add_member(b, x);
            y = top[mate[x]];
            add_member(b, y);
            enqueue_members(y);
        }
        std::reverse(members[b] + 1, members[b] + member_count[b]);
        for (int x = v, y; x != base; x = top[parent[y]]) {
            add_member(b, x);
            y = top[mate[x]];
            add_member(b, y);
            enqueue_members(y);
        }
        set_top(b, b);

        for (int x = 1; x <= nodes; ++x) {
            weight[b][x] = weight[x][b] = 0;
            endpoint_a[b][x] = endpoint_b[b][x] = 0;
            endpoint_a[x][b] = endpoint_b[x][b] = 0;
        }
        for (int leaf = 1; leaf <= n; ++leaf) child_of[b][leaf] = 0;
        for (int i = 0; i < member_count[b]; ++i) {
            const int child = members[b][i];
            for (int x = 1; x <= nodes; ++x) {
                if (weight[child][x] == 0) continue;
                if (weight[b][x] == 0 || reduced_cost(child, x) < reduced_cost(b, x)) {
                    weight[b][x] = weight[child][x];
                    endpoint_a[b][x] = endpoint_a[child][x];
                    endpoint_b[b][x] = endpoint_b[child][x];
                    weight[x][b] = weight[x][child];
                    endpoint_a[x][b] = endpoint_a[x][child];
                    endpoint_b[x][b] = endpoint_b[x][child];
                }
            }
            for (int leaf = 1; leaf <= n; ++leaf) {
                const bool contained = child <= n ? child == leaf : child_of[child][leaf] != 0;
                if (contained) child_of[b][leaf] = static_cast<std::int16_t>(child);
            }
        }
        refresh_slack(b);
    }

    void expand(int b) {
        for (int i = 0; i < member_count[b]; ++i) set_top(members[b][i], members[b][i]);
        const int outside = parent[b];
        const int entry_leaf = endpoint_a[b][outside];
        const int entry = child_of[b][entry_leaf];
        const int pos = cycle_position(b, entry);
        for (int i = 0; i < pos; i += 2) {
            const int inner = members[b][i], outer = members[b][i + 1];
            parent[inner] = endpoint_a[outer][inner];
            label[inner] = 1;
            label[outer] = 0;
            slack_from[inner] = 0;
            refresh_slack(outer);
            enqueue_members(outer);
        }
        label[entry] = 1;
        parent[entry] = static_cast<std::int16_t>(outside);
        for (int i = pos + 1; i < member_count[b]; ++i) {
            const int child = members[b][i];
            label[child] = -1;
            refresh_slack(child);
        }
        top[b] = 0;
    }

    bool process_edge(int left, int right) {
        const int u = top[left], v = top[right];
        if (label[v] == -1) {
            parent[v] = static_cast<std::int16_t>(left);
            label[v] = 1;
            const int next = top[mate[v]];
            slack_from[v] = slack_from[next] = 0;
            label[next] = 0;
            enqueue_members(next);
        } else if (label[v] == 0) {
            const int base = common_base(u, v);
            if (base == 0) {
                augment(u, v);
                augment(v, u);
                return true;
            }
            contract(u, base, v);
        }
        return false;
    }

    bool stage() {
        for (int x = 0; x <= nodes; ++x) label[x] = -1, slack_from[x] = 0;
        head = tail = count = 0;
        queued.fill(false);
        for (int x = 1; x <= nodes; ++x) {
            if (top[x] == x && mate[x] == 0) {
                parent[x] = 0;
                label[x] = 0;
                enqueue_members(x);
            }
        }
        if (count == 0) return false;

        for (;;) {
            while (count != 0) {
                const int u = queue[head];
                head = (head + 1) % n;
                --count;
                queued[u] = false;
                if (label[top[u]] == 1) continue;
                for (int v = 1; v <= n; ++v) {
                    if (weight[u][v] == 0 || top[u] == top[v]) continue;
                    if (reduced_cost(u, v) == 0) {
                        if (process_edge(endpoint_a[u][v], endpoint_b[u][v])) return true;
                    } else {
                        const int x = top[v], old = slack_from[x];
                        if (old == 0 || reduced_cost(u, x) < reduced_cost(old, x))
                            slack_from[x] = static_cast<std::int16_t>(u);
                    }
                }
            }

            std::int64_t step = kInfinity;
            for (int u = 1; u <= n; ++u)
                if (label[top[u]] == 0) step = std::min(step, dual[u]);
            for (int b = n + 1; b <= nodes; ++b)
                if (top[b] == b && label[b] == 1) step = std::min(step, dual[b] / 2);
            for (int x = 1; x <= nodes; ++x) {
                if (top[x] != x || slack_from[x] == 0) continue;
                const auto slack = reduced_cost(slack_from[x], x);
                if (label[x] == -1) step = std::min(step, slack);
                else if (label[x] == 0) step = std::min(step, slack / 2);
            }
            if (step == kInfinity) return false;

            for (int u = 1; u <= n; ++u) {
                if (label[top[u]] == 0) {
                    if (dual[u] == step) return false;
                    dual[u] -= step;
                } else if (label[top[u]] == 1) {
                    dual[u] += step;
                }
            }
            for (int b = n + 1; b <= nodes; ++b) {
                if (top[b] != b) continue;
                if (label[b] == 0) dual[b] += 2 * step;
                else if (label[b] == 1) dual[b] -= 2 * step;
            }

            for (int x = 1; x <= nodes; ++x) {
                if (top[x] == x && slack_from[x] != 0 && top[slack_from[x]] != x &&
                    reduced_cost(slack_from[x], x) == 0) {
                    const int from = slack_from[x];
                    if (process_edge(endpoint_a[from][x], endpoint_b[from][x])) return true;
                }
            }
            for (int b = n + 1; b <= nodes; ++b)
                if (top[b] == b && label[b] == 1 && dual[b] == 0) expand(b);
        }
    }
};
}  // namespace

extern "C" std::int64_t general_weighted_matching_primal_dual_blossom(
    const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > 6051) return -2;
    const auto nv = input[0], mv = input[1];
    if (nv < 1 || nv > kMaxN || mv < 0 || mv > nv * (nv - 1) / 2) return -2;
    const int n = static_cast<int>(nv), m = static_cast<int>(mv);
    if (length != static_cast<std::size_t>(2 + 3 * m)) return -2;

    BlossomSearch search{};
    search.n = search.nodes = n;
    std::int64_t largest = 0;
    for (int edge = 0; edge < m; ++edge) {
        const auto u_value = input[2 + 3 * edge];
        const auto v_value = input[3 + 3 * edge];
        const auto value = input[4 + 3 * edge];
        if (u_value < 0 || u_value >= nv || v_value < 0 || v_value >= nv ||
            u_value == v_value || value < 1 || value > 1'000'000) return -2;
        const int u = static_cast<int>(u_value) + 1, v = static_cast<int>(v_value) + 1;
        if (search.weight[u][v] != 0) return -2;
        search.weight[u][v] = search.weight[v][u] = value;
        search.endpoint_a[u][v] = static_cast<std::int16_t>(u);
        search.endpoint_b[u][v] = static_cast<std::int16_t>(v);
        search.endpoint_a[v][u] = static_cast<std::int16_t>(v);
        search.endpoint_b[v][u] = static_cast<std::int16_t>(u);
        largest = std::max(largest, value);
    }
    for (int u = 1; u <= n; ++u) {
        search.top[u] = static_cast<std::int16_t>(u);
        search.dual[u] = largest;
        search.child_of[u][u] = static_cast<std::int16_t>(u);
    }
    while (search.stage()) { }
    std::int64_t total = 0;
    for (int u = 1; u <= n; ++u)
        if (search.mate[u] > u) total += search.weight[u][search.mate[u]];
    return total;
}
