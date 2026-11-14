// Independent event-graph draft; compilation and correctness are unverified.
#include <cstddef>
#include <cstdint>
#include <queue>
#include <vector>

namespace range_constraint_draft {
struct Graph {
    std::vector<std::vector<int>> edges;
    std::vector<int> degree;
    std::vector<bool> first;
    int node(bool any = false) {
        edges.emplace_back(); degree.push_back(0); first.push_back(any);
        return static_cast<int>(edges.size()) - 1;
    }
    void add(int from, int to) { edges[from].push_back(to); ++degree[to]; }
};
struct Trees {
    Graph& graph;
    std::vector<int> down, up, any;
    Trees(Graph& g, int n) : graph(g), down(4*n), up(4*n), any(4*n) { build(1, 0, n); }
    void build(int t, int l, int r) {
        down[t] = graph.node(); up[t] = graph.node(); any[t] = graph.node(true);
        if (r-l == 1) {
            graph.add(down[t], l); graph.add(l, up[t]); graph.add(l, any[t]);
            return;
        }
        int mid = l + (r-l)/2;
        build(2*t, l, mid); build(2*t+1, mid, r);
        for (int child : {2*t, 2*t+1}) {
            graph.add(down[t], down[child]);
            graph.add(up[child], up[t]);
            graph.add(any[child], any[t]);
        }
    }
    void connect(int t, int l, int r, int ql, int qr, int kind, int target) {
        if (ql <= l && r <= qr) {
            if (kind == 1) graph.add(target, down[t]);
            else if (kind == 2) graph.add(up[t], target);
            else graph.add(any[t], target);
            return;
        }
        int mid = l + (r-l)/2;
        if (ql < mid) connect(2*t, l, mid, ql, qr, kind, target);
        if (qr > mid) connect(2*t+1, mid, r, ql, qr, kind, target);
    }
};
}

extern "C" std::int64_t range_constraint_topological_feasibility(const std::int64_t* input,
                                                                    std::size_t length) {
    using namespace range_constraint_draft;
    if (!input || length < 2 || input[0] < 1 || input[0] > 4096 || input[1] < 0 || input[1] > 8192) return -1;
    const int n = static_cast<int>(input[0]), m = static_cast<int>(input[1]);
    if (length != 2 + 4 * static_cast<std::size_t>(m)) return -1;
    for (int i = 0; i < m; ++i) {
        const auto kind=input[2+4*i], l=input[3+4*i], r=input[4+4*i], v=input[5+4*i];
        if (kind < 1 || kind > 3 || l < 0 || l >= r || r > n || v < 0 || v >= n || (l <= v && v < r)) return -1;
    }
    Graph graph;
    for (int i=0; i<n; ++i) graph.node();
    Trees trees(graph, n);
    for (int i=0; i<m; ++i) {
        int kind=static_cast<int>(input[2+4*i]);
        int l=static_cast<int>(input[3+4*i]), r=static_cast<int>(input[4+4*i]);
        int target=static_cast<int>(input[5+4*i]);
        if (kind==3) {
            int gate=graph.node(true);
            trees.connect(1,0,n,l,r,kind,gate);
            graph.add(gate,target);
        } else trees.connect(1,0,n,l,r,kind,target);
    }
    for (std::size_t i=0; i<graph.degree.size(); ++i)
        if (graph.first[i]) graph.degree[i]=1;
    std::queue<int> ready;
    for (std::size_t i=0; i<graph.degree.size(); ++i)
        if (graph.degree[i]==0) ready.push(static_cast<int>(i));
    int emitted=0;
    while (!ready.empty()) {
        int u=ready.front(); ready.pop();
        if (u<n) ++emitted;
        for (int v : graph.edges[u])
            if (graph.degree[v]>0 && --graph.degree[v]==0) ready.push(v);
    }
    return emitted==n ? 1 : 0;
}
