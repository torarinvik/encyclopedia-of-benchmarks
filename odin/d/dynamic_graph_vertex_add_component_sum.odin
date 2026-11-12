package dynamic_graph_vertex_add_component_sum

import "core:c"

MAX_N :: 16
MAX_Q :: 32
MAX_INTERVALS :: MAX_N + 2 * MAX_Q
TREE_NODES :: 4 * MAX_Q + 8

Time_Op :: struct { kind, a, b: int; delta: i64 }
Change :: struct { kind, a, root, old_size: int; old_sum: i64 }

root_of :: proc "contextless" (parent: [^]int, input_vertex: int) -> int {
    vertex := input_vertex
    for parent[vertex] != vertex { vertex = parent[vertex] }
    return vertex
}

place_interval :: proc "contextless" (node, left, right, ql, qr, id: int,
    count, bucket: [^]int) {
    if ql <= left && right <= qr { bucket[node * MAX_INTERVALS + count[node]] = id; count[node] += 1; return }
    mid := left + (right-left)/2
    if ql < mid { place_interval(node*2,left,mid,ql,qr,id,count,bucket) }
    if qr > mid { place_interval(node*2+1,mid,right,ql,qr,id,count,bucket) }
}

unite :: proc "contextless" (u, v: int, parent, size: [^]int, total: [^]i64,
    history: [^]Change, history_len: ^int) {
    ru := root_of(parent,u); rv := root_of(parent,v)
    if ru == rv do return
    if size[ru] < size[rv] || (size[ru] == size[rv] && ru > rv) { ru,rv = rv,ru }
    history[history_len^] = Change{0,rv,ru,size[ru],total[ru]}; history_len^ += 1
    parent[rv] = ru; size[ru] += size[rv]; total[ru] += total[rv]
}

add_value :: proc "contextless" (v: int, delta: i64, parent: [^]int,
    total: [^]i64, history: [^]Change, history_len: ^int) {
    r := root_of(parent,v)
    history[history_len^] = Change{1,r,0,0,total[r]}; history_len^ += 1; total[r] += delta
}

rollback :: proc "contextless" (mark: int, parent, size: [^]int, total: [^]i64,
    history: [^]Change, history_len: ^int) {
    for history_len^ > mark {
        history_len^ -= 1; c := history[history_len^]
        if c.kind == 0 { parent[c.a] = c.a; size[c.root] = c.old_size; total[c.root] = c.old_sum }
        else { total[c.a] = c.old_sum }
    }
}

visit :: proc "contextless" (node, left, right: int, ops: [^]Time_Op,
    counts, bucket: [^]int, event_op, event_a: [^]i64, parent, size: [^]int,
    total: [^]i64, history: [^]Change, history_len: ^int, answer: [^]i64) {
    mark := history_len^
    for i := 0; i < counts[node]; i += 1 {
        op := ops[bucket[node * MAX_INTERVALS + i]]
        if op.kind == 0 { unite(op.a,op.b,parent,size,total,history,history_len) }
        else { add_value(op.a,op.delta,parent,total,history,history_len) }
    }
    if right-left == 1 {
        if event_op[left] == 3 { answer[left] = total[root_of(parent,int(event_a[left]))] }
    } else {
        mid := left+(right-left)/2
        visit(node*2,left,mid,ops,counts,bucket,event_op,event_a,parent,size,total,history,history_len,answer)
        visit(node*2+1,mid,right,ops,counts,bucket,event_op,event_a,parent,size,total,history,history_len,answer)
    }
    rollback(mark,parent,size,total,history,history_len)
}

store_i64_le :: proc "contextless" (out: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for b := 0; b < 8; b += 1 { out[offset+b] = u8(bits >> u64(8*b)) }
}

@(export)
dynamic_graph_vertex_add_component_sum :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 2+MAX_N+3*MAX_Q+1 do return -1
    if input[0] < 1 || input[0] > MAX_N || input[1] < 0 || input[1] > MAX_Q do return -1
    n := int(input[0]); q := int(input[1])
    if length != c.size_t(2+n+3*q) do return -1
    initial: [MAX_N]i64
    for v := 0; v < n; v += 1 { initial[v] = input[2+v]; if initial[v] < 0 || initial[v] > 100 do return -1 }
    event_op: [MAX_Q]i64; event_a: [MAX_Q]i64; event_b: [MAX_Q]i64
    active: [MAX_N * MAX_N]bool
    start: [MAX_N * MAX_N]int
    ops: [MAX_INTERVALS]Time_Op
    interval_left: [MAX_INTERVALS]int; interval_right: [MAX_INTERVALS]int
    op_count := 0; query_count := 0
    for t := 0; t < q; t += 1 {
        off := 2+n+3*t; op := input[off]; a := input[off+1]; b := input[off+2]
        event_op[t]=op; event_a[t]=a; event_b[t]=b
        if op == 0 || op == 1 {
            if a < 0 || a >= n || b < 0 || b >= n || a == b do return -1
            u := int(a); v := int(b); if u > v { u,v = v,u }; ix := u*MAX_N+v
            if op == 0 { if active[ix] do return -1; active[ix]=true; start[ix]=t }
            else { if !active[ix] do return -1; active[ix]=false; if start[ix] < t { ops[op_count]=Time_Op{0,u,v,0}; interval_left[op_count]=start[ix]; interval_right[op_count]=t; op_count+=1 } }
        } else if op == 2 {
            if a < 0 || a >= n || b < 0 || b > 100 do return -1
            if b != 0 && t < q { ops[op_count]=Time_Op{1,int(a),0,b}; interval_left[op_count]=t; interval_right[op_count]=q; op_count+=1 }
        } else if op == 3 { if a < 0 || a >= n || b != 0 do return -1; query_count += 1 }
        else { return -1 }
    }
    for u := 0; u < n; u += 1 for v := u+1; v < n; v += 1 {
        ix := u*MAX_N+v
        if active[ix] && start[ix] < q { ops[op_count]=Time_Op{0,u,v,0}; interval_left[op_count]=start[ix]; interval_right[op_count]=q; op_count+=1 }
    }
    if q != 0 for v := 0; v < n; v += 1 if initial[v] != 0 { ops[op_count]=Time_Op{1,v,0,initial[v]}; interval_left[op_count]=0; interval_right[op_count]=q; op_count+=1 }
    if output == nil || capacity < c.size_t(8*query_count) do return -2
    bucket_count: [TREE_NODES]int
    bucket: [TREE_NODES * MAX_INTERVALS]int
    if q != 0 for i := 0; i < op_count; i += 1 if interval_left[i] < interval_right[i] { place_interval(1,0,q,interval_left[i],interval_right[i],i,&bucket_count[0],&bucket[0]) }
    parent: [MAX_N]int; size: [MAX_N]int; total: [MAX_N]i64
    for v := 0; v < n; v += 1 { parent[v]=v; size[v]=1 }
    history: [MAX_INTERVALS]Change; history_len := 0; answer: [MAX_Q]i64
    if q != 0 { visit(1,0,q,&ops[0],&bucket_count[0],&bucket[0],&event_op[0],&event_a[0],&parent[0],&size[0],&total[0],&history[0],&history_len,&answer[0]) }
    written := 0
    for t := 0; t < q; t += 1 if event_op[t] == 3 { store_i64_le(output,written,answer[t]); written += 8 }
    return i64(written)
}
