module dynamic_graph_vertex_add_component_sum;

const int MAX_N = 16;
const int MAX_Q = 32;
const int MAX_INTERVALS = MAX_N + 2 * MAX_Q;
const int TREE_NODES = 4 * MAX_Q + 8;

struct TimeOp { usz kind; usz a; usz b; long delta; }

fn usz root_of(usz[MAX_N]* parent, usz v) {
    while (parent[v] != v) v = parent[v];
    return v;
}

fn void place(usz node, usz left, usz right, usz ql, usz qr, usz id,
    usz[TREE_NODES]* count, usz[TREE_NODES][MAX_INTERVALS]* bucket) {
    if (ql <= left && right <= qr) {
        bucket[node][count[node]] = id;
        count[node] += 1;
        return;
    }
    usz mid = left + (right - left) / 2;
    if (ql < mid) place(2 * node, left, mid, ql, qr, id, count, bucket);
    if (qr > mid) place(2 * node + 1, mid, right, ql, qr, id, count, bucket);
}

fn void unite(usz u, usz v, usz[MAX_N]* parent, usz[MAX_N]* size,
    long[MAX_N]* total, usz[MAX_INTERVALS]* hk, usz[MAX_INTERVALS]* ha,
    usz[MAX_INTERVALS]* hb, usz[MAX_INTERVALS]* hs,
    long[MAX_INTERVALS]* hv, usz* hp) {
    usz ru = root_of(parent, u), rv = root_of(parent, v);
    if (ru == rv) return;
    if (size[ru] < size[rv] || (size[ru] == size[rv] && ru > rv)) {
        usz tmp = ru; ru = rv; rv = tmp;
    }
    hk[*hp] = 0; ha[*hp] = rv; hb[*hp] = ru;
    hs[*hp] = size[ru]; hv[*hp] = total[ru]; *hp += 1;
    parent[rv] = ru; size[ru] += size[rv]; total[ru] += total[rv];
}

fn void add_value(usz v, long delta, usz[MAX_N]* parent, long[MAX_N]* total,
    usz[MAX_INTERVALS]* hk, usz[MAX_INTERVALS]* ha, long[MAX_INTERVALS]* hv,
    usz* hp) {
    usz r = root_of(parent, v);
    hk[*hp] = 1; ha[*hp] = r; hv[*hp] = total[r]; *hp += 1;
    total[r] += delta;
}

fn void rollback(usz mark, usz[MAX_N]* parent, usz[MAX_N]* size,
    long[MAX_N]* total, usz[MAX_INTERVALS]* hk, usz[MAX_INTERVALS]* ha,
    usz[MAX_INTERVALS]* hb, usz[MAX_INTERVALS]* hs,
    long[MAX_INTERVALS]* hv, usz* hp) {
    while (*hp > mark) {
        *hp -= 1;
        usz k = hk[*hp], a = ha[*hp];
        if (k == 0) {
            usz r = hb[*hp]; parent[a] = a; size[r] = hs[*hp]; total[r] = hv[*hp];
        } else total[a] = hv[*hp];
    }
}

fn void visit(usz node, usz left, usz right, TimeOp[MAX_INTERVALS]* ops,
    usz[TREE_NODES]* count, usz[TREE_NODES][MAX_INTERVALS]* bucket,
    long[MAX_Q]* event_op, long[MAX_Q]* event_a, usz[MAX_N]* parent,
    usz[MAX_N]* size, long[MAX_N]* total, usz[MAX_INTERVALS]* hk,
    usz[MAX_INTERVALS]* ha, usz[MAX_INTERVALS]* hb, usz[MAX_INTERVALS]* hs,
    long[MAX_INTERVALS]* hv, usz* hp, long[MAX_Q]* answer) {
    usz mark = *hp;
    for (usz i = 0; i < count[node]; i += 1) {
        TimeOp op = ops[bucket[node][i]];
        if (op.kind == 0) unite(op.a, op.b, parent, size, total, hk, ha, hb, hs, hv, hp);
        else add_value(op.a, op.delta, parent, total, hk, ha, hv, hp);
    }
    if (right - left == 1) {
        if (event_op[left] == 3) answer[left] = total[root_of(parent, (usz)event_a[left])];
    } else {
        usz mid = left + (right - left) / 2;
        visit(2 * node, left, mid, ops, count, bucket, event_op, event_a,
            parent, size, total, hk, ha, hb, hs, hv, hp, answer);
        visit(2 * node + 1, mid, right, ops, count, bucket, event_op, event_a,
            parent, size, total, hk, ha, hb, hs, hv, hp, answer);
    }
    rollback(mark, parent, size, total, hk, ha, hb, hs, hv, hp);
}

fn void store_le(uint8* out, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz i = 0; i < 8; i += 1) out[offset + i] = (uint8)((bits >> (8 * i)) & 255);
}

fn long dynamic_graph_vertex_add_component_sum(long* input, usz length,
    uint8* output, usz capacity) @export("dynamic_graph_vertex_add_component_sum") {
    if (input == null || length < 2 || length > 2 + MAX_N + 3 * MAX_Q + 1) return -1;
    if (input[0] < 1 || input[0] > MAX_N || input[1] < 0 || input[1] > MAX_Q) return -1;
    usz n = (usz)input[0], q = (usz)input[1];
    if (length != 2 + n + 3 * q) return -1;
    long[MAX_N] initial;
    for (usz v = 0; v < n; v += 1) {
        initial[v] = input[2 + v];
        if (initial[v] < 0 || initial[v] > 100) return -1;
    }
    long[MAX_Q] event_op, event_a, event_b;
    bool[MAX_N][MAX_N] active = zeroed;
    usz[MAX_N][MAX_N] starts = zeroed;
    TimeOp[MAX_INTERVALS] ops;
    usz[MAX_INTERVALS] il, ir;
    usz op_count = 0, query_count = 0;
    for (usz t = 0; t < q; t += 1) {
        usz off = 2 + n + 3 * t;
        long op = input[off], a = input[off + 1], b = input[off + 2];
        event_op[t] = op; event_a[t] = a; event_b[t] = b;
        if (op == 0 || op == 1) {
            if (a < 0 || a >= (long)n || b < 0 || b >= (long)n || a == b) return -1;
            usz u = (usz)a, v = (usz)b;
            if (u > v) { usz tmp = u; u = v; v = tmp; }
            if (op == 0) {
                if (active[u][v]) return -1;
                active[u][v] = true; starts[u][v] = t;
            } else {
                if (!active[u][v]) return -1;
                active[u][v] = false;
                if (starts[u][v] < t) {
                    ops[op_count] = TimeOp{0,u,v,0}; il[op_count] = starts[u][v]; ir[op_count] = t; op_count += 1;
                }
            }
        } else if (op == 2) {
            if (a < 0 || a >= (long)n || b < 0 || b > 100) return -1;
            if (b != 0 && t < q) {
                ops[op_count] = TimeOp{1,(usz)a,0,b}; il[op_count] = t; ir[op_count] = q; op_count += 1;
            }
        } else if (op == 3) {
            if (a < 0 || a >= (long)n || b != 0) return -1;
            query_count += 1;
        } else return -1;
    }
    for (usz u = 0; u < n; u += 1) for (usz v = u + 1; v < n; v += 1) {
        if (active[u][v] && starts[u][v] < q) {
            ops[op_count] = TimeOp{0,u,v,0}; il[op_count] = starts[u][v]; ir[op_count] = q; op_count += 1;
        }
    }
    if (q != 0) for (usz v = 0; v < n; v += 1) if (initial[v] != 0) {
        ops[op_count] = TimeOp{1,v,0,initial[v]}; il[op_count] = 0; ir[op_count] = q; op_count += 1;
    }
    if (output == null || capacity < 8 * query_count) return -2;
    usz[TREE_NODES] counts = zeroed;
    usz[TREE_NODES][MAX_INTERVALS] bucket;
    if (q != 0) for (usz i = 0; i < op_count; i += 1)
        if (il[i] < ir[i]) place(1,0,q,il[i],ir[i],i,&counts,&bucket);
    usz[MAX_N] parent, size;
    long[MAX_N] total = zeroed;
    for (usz v = 0; v < n; v += 1) { parent[v] = v; size[v] = 1; }
    usz[MAX_INTERVALS] hk, ha, hb, hs;
    long[MAX_INTERVALS] hv;
    usz hp = 0;
    long[MAX_Q] answer = zeroed;
    if (q != 0) visit(1,0,q,&ops,&counts,&bucket,&event_op,&event_a,&parent,&size,&total,&hk,&ha,&hb,&hs,&hv,&hp,&answer);
    usz written = 0;
    for (usz t = 0; t < q; t += 1) if (event_op[t] == 3) { store_le(output,written,answer[t]); written += 8; }
    return (long)written;
}
