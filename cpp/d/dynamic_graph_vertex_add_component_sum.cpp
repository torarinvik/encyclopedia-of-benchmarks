#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t NMAX = 16, QMAX = 32;
constexpr std::size_t OMAX = NMAX + 2 * QMAX, TMAX = 4 * QMAX + 8;
struct Op { std::size_t kind, a, b; std::int64_t delta; };

std::size_t find_root(const std::size_t *parent, std::size_t v) {
    while (parent[v] != v) v = parent[v];
    return v;
}
void put_interval(std::size_t node, std::size_t l, std::size_t r,
                  std::size_t ql, std::size_t qr, std::size_t id,
                  std::size_t count[TMAX], std::size_t bucket[TMAX][OMAX]) {
    if (ql <= l && r <= qr) { bucket[node][count[node]++] = id; return; }
    const auto mid = l + (r - l) / 2;
    if (ql < mid) put_interval(node * 2, l, mid, ql, qr, id, count, bucket);
    if (qr > mid) put_interval(node * 2 + 1, mid, r, ql, qr, id, count, bucket);
}
struct History {
    bool is_union[OMAX];
    std::size_t a[OMAX], b[OMAX], old_size[OMAX], length = 0;
    std::int64_t old_sum[OMAX];
};
void unite(std::size_t u, std::size_t v, std::size_t parent[NMAX],
           std::size_t size[NMAX], std::int64_t sum[NMAX], History &h) {
    auto ru = find_root(parent, u), rv = find_root(parent, v);
    if (ru == rv) return;
    if (size[ru] < size[rv] || (size[ru] == size[rv] && ru > rv)) {
        const auto tmp = ru; ru = rv; rv = tmp;
    }
    const auto k = h.length++;
    h.is_union[k] = true; h.a[k] = rv; h.b[k] = ru;
    h.old_size[k] = size[ru]; h.old_sum[k] = sum[ru];
    parent[rv] = ru; size[ru] += size[rv]; sum[ru] += sum[rv];
}
void add_value(std::size_t v, std::int64_t d, std::size_t parent[NMAX],
               std::int64_t sum[NMAX], History &h) {
    const auto r = find_root(parent, v), k = h.length++;
    h.is_union[k] = false; h.a[k] = r; h.old_sum[k] = sum[r]; sum[r] += d;
}
void rollback(std::size_t mark, std::size_t parent[NMAX], std::size_t size[NMAX],
              std::int64_t sum[NMAX], History &h) {
    while (h.length > mark) {
        const auto k = --h.length, a = h.a[k];
        if (h.is_union[k]) {
            const auto r = h.b[k]; parent[a] = a;
            size[r] = h.old_size[k]; sum[r] = h.old_sum[k];
        } else sum[a] = h.old_sum[k];
    }
}
void walk(std::size_t node, std::size_t l, std::size_t r, const Op ops[OMAX],
          const std::size_t count[TMAX], const std::size_t bucket[TMAX][OMAX],
          const std::int64_t event_op[QMAX], const std::int64_t event_a[QMAX],
          std::size_t parent[NMAX], std::size_t size[NMAX], std::int64_t sum[NMAX],
          History &h, std::int64_t answer[QMAX]) {
    const auto mark = h.length;
    for (std::size_t i = 0; i < count[node]; ++i) {
        const auto op = ops[bucket[node][i]];
        if (op.kind == 0) unite(op.a, op.b, parent, size, sum, h);
        else add_value(op.a, op.delta, parent, sum, h);
    }
    if (r - l == 1) {
        if (event_op[l] == 3) answer[l] = sum[find_root(parent, static_cast<std::size_t>(event_a[l]))];
    } else {
        const auto mid = l + (r - l) / 2;
        walk(node * 2, l, mid, ops, count, bucket, event_op, event_a,
             parent, size, sum, h, answer);
        walk(node * 2 + 1, mid, r, ops, count, bucket, event_op, event_a,
             parent, size, sum, h, answer);
    }
    rollback(mark, parent, size, sum, h);
}
void store_le(std::uint8_t *out, std::size_t off, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t i = 0; i < 8; ++i) out[off + i] = static_cast<std::uint8_t>(bits >> (8 * i));
}
}

extern "C" std::int64_t dynamic_graph_vertex_add_component_sum(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) {
    if (input == nullptr || length < 2 || length > 2 + NMAX + 3 * QMAX + 1) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(NMAX) ||
        input[1] < 0 || input[1] > static_cast<std::int64_t>(QMAX)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto q = static_cast<std::size_t>(input[1]);
    if (length != 2 + n + 3 * q) return -1;
    std::int64_t initial[NMAX]{};
    for (std::size_t v = 0; v < n; ++v) {
        initial[v] = input[2 + v];
        if (initial[v] < 0 || initial[v] > 100) return -1;
    }
    std::int64_t event_op[QMAX]{}, event_a[QMAX]{}, event_b[QMAX]{};
    bool active[NMAX][NMAX]{};
    std::size_t start[NMAX][NMAX]{};
    Op ops[OMAX]{};
    std::size_t il[OMAX]{}, ir[OMAX]{}, op_count = 0, query_count = 0;
    for (std::size_t t = 0; t < q; ++t) {
        const auto off = 2 + n + 3 * t;
        const auto op = input[off], a = input[off + 1], b = input[off + 2];
        event_op[t] = op; event_a[t] = a; event_b[t] = b;
        if (op == 0 || op == 1) {
            if (a < 0 || a >= static_cast<std::int64_t>(n) || b < 0 || b >= static_cast<std::int64_t>(n) || a == b) return -1;
            auto u = static_cast<std::size_t>(a), v = static_cast<std::size_t>(b);
            if (u > v) { const auto tmp = u; u = v; v = tmp; }
            if (op == 0) {
                if (active[u][v]) return -1;
                active[u][v] = true; start[u][v] = t;
            } else {
                if (!active[u][v]) return -1;
                active[u][v] = false;
                if (start[u][v] < t) { ops[op_count] = {0,u,v,0}; il[op_count] = start[u][v]; ir[op_count++] = t; }
            }
        } else if (op == 2) {
            if (a < 0 || a >= static_cast<std::int64_t>(n) || b < 0 || b > 100) return -1;
            if (b != 0 && t < q) { ops[op_count] = {1,static_cast<std::size_t>(a),0,b}; il[op_count] = t; ir[op_count++] = q; }
        } else if (op == 3) {
            if (a < 0 || a >= static_cast<std::int64_t>(n) || b != 0) return -1;
            ++query_count;
        } else return -1;
    }
    for (std::size_t u = 0; u < n; ++u) for (std::size_t v = u + 1; v < n; ++v)
        if (active[u][v] && start[u][v] < q) { ops[op_count] = {0,u,v,0}; il[op_count] = start[u][v]; ir[op_count++] = q; }
    if (q != 0) for (std::size_t v = 0; v < n; ++v) if (initial[v] != 0) {
        ops[op_count] = {1,v,0,initial[v]}; il[op_count] = 0; ir[op_count++] = q;
    }
    if (output == nullptr || capacity < 8 * query_count) return -2;
    std::size_t count[TMAX]{}, bucket[TMAX][OMAX]{};
    if (q != 0) for (std::size_t i = 0; i < op_count; ++i)
        if (il[i] < ir[i]) put_interval(1,0,q,il[i],ir[i],i,count,bucket);
    std::size_t parent[NMAX]{}, size[NMAX]{};
    std::int64_t sum[NMAX]{};
    for (std::size_t v = 0; v < n; ++v) { parent[v] = v; size[v] = 1; }
    History history{};
    std::int64_t answer[QMAX]{};
    if (q != 0) walk(1,0,q,ops,count,bucket,event_op,event_a,parent,size,sum,history,answer);
    std::size_t written = 0;
    for (std::size_t t = 0; t < q; ++t) if (event_op[t] == 3) { store_le(output,written,answer[t]); written += 8; }
    return static_cast<std::int64_t>(written);
}
