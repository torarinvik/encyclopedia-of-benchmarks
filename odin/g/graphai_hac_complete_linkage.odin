// Clean-room bounded GraphAIBench complete-linkage HAC; see package LICENSE.txt.
package graphai_hac_complete_linkage

import "core:c"

MAX_N :: 8
MAX_M :: 24
MAX_INPUT :: 74
MAX_NODES :: 15
ROOT_PARENT :: i64(4_294_967_295)

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset+byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
graphai_hac_complete_linkage :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT do return -1
    n64, m64 := input[0], input[1]
    if n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M do return -1
    n, m := int(n64), int(m64)
    if length != c.size_t(2+3*m) do return -1
    adjacency: [MAX_N*MAX_N]int
    used_weight: [33]bool
    for edge := 0; edge < m; edge += 1 {
        u64, v64, w64 := input[2+3*edge], input[3+3*edge], input[4+3*edge]
        if u64 < 0 || v64 <= u64 || v64 >= n64 || w64 < 1 || w64 > 32 do return -1
        u, v, w := int(u64), int(v64), int(w64)
        if adjacency[u*MAX_N+v] != 0 || used_weight[w] do return -1
        adjacency[u*MAX_N+v], adjacency[v*MAX_N+u], used_weight[w] = w, w, true
    }
    reached: [MAX_N]bool
    queue: [MAX_N]int
    reached[0] = true
    head, tail := 0, 1
    for head < tail {
        u := queue[head]; head += 1
        for v := 0; v < n; v += 1 {
            if adjacency[u*MAX_N+v] != 0 && !reached[v] { reached[v] = true; queue[tail] = v; tail += 1 }
        }
    }
    for v := 0; v < n; v += 1 { if !reached[v] do return -1 }
    node_count := 2*n-1
    output_bytes := 16*node_count
    if output == nil || capacity < c.size_t(output_bytes) do return -2
    active: [MAX_N]bool
    current_id: [MAX_N]int
    parent: [MAX_NODES]i64
    merge_weight: [MAX_NODES]i64
    for node := 0; node < MAX_NODES; node += 1 { parent[node] = ROOT_PARENT }
    for u := 0; u < n; u += 1 { active[u] = true; current_id[u] = u }
    for merge := 0; merge < n-1; merge += 1 {
        best_u, best_v, best_weight := -1, -1, 0
        for u := 0; u < n; u += 1 {
            if active[u] {
                for v := u+1; v < n; v += 1 {
                    if active[v] && adjacency[u*MAX_N+v] > best_weight {
                        best_u, best_v, best_weight = u, v, adjacency[u*MAX_N+v]
                    }
                }
            }
        }
        if best_u < 0 do return -1
        degree_u, degree_v := 0, 0
        for z := 0; z < n; z += 1 {
            if active[z] && adjacency[best_u*MAX_N+z] != 0 { degree_u += 1 }
            if active[z] && adjacency[best_v*MAX_N+z] != 0 { degree_v += 1 }
        }
        larger := best_u
        if degree_u < degree_v { larger = best_v }
        smaller := best_u
        if larger == best_u { smaller = best_v }
        new_id := n+merge
        parent[current_id[best_u]], parent[current_id[best_v]] = i64(new_id), i64(new_id)
        merge_weight[current_id[best_u]], merge_weight[current_id[best_v]] = i64(best_weight), i64(best_weight)
        merged_weight: [MAX_N]int
        for z := 0; z < n; z += 1 {
            if active[z] && z != best_u && z != best_v {
                a, b := adjacency[best_u*MAX_N+z], adjacency[best_v*MAX_N+z]
                if a != 0 || b != 0 { merged_weight[z] = if a != 0 && b != 0 { min(a,b) } else if a != 0 { a } else { b } }
            }
        }
        for z := 0; z < n; z += 1 {
            adjacency[best_u*MAX_N+z], adjacency[z*MAX_N+best_u] = 0, 0
            adjacency[best_v*MAX_N+z], adjacency[z*MAX_N+best_v] = 0, 0
        }
        active[smaller] = false
        for z := 0; z < n; z += 1 {
            if active[z] && z != larger && merged_weight[z] != 0 {
                adjacency[larger*MAX_N+z], adjacency[z*MAX_N+larger] = merged_weight[z], merged_weight[z]
            }
        }
        current_id[larger] = new_id
    }
    for node := 0; node < node_count; node += 1 {
        store_i64_le(output, 16*node, parent[node])
        store_i64_le(output, 16*node+8, merge_weight[node])
    }
    return i64(output_bytes)
}
