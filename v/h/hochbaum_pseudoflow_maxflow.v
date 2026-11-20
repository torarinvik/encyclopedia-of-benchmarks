module hochbaum_pseudoflow_maxflow

const pf_n = 8
const pf_k = 6
const pf_m = 24
const pf_iterations = 512

fn pf_build_state(k int, root_edge [pf_k]int, tree_edges [pf_n]int, tree_count int,
                  edge_u [pf_m]int, edge_v [pf_m]int, mut parent [pf_n + 1]int,
                  mut parent_edge [pf_n + 1]int, mut branch_root [pf_k]int) bool {
    root := k
    mut adjacency := [81]int{}
    for i in 0 .. 81 { adjacency[i] = -2 }
    for v in 0 .. k {
        if root_edge[v] != 0 { adjacency[root * 9 + v] = -1; adjacency[v * 9 + root] = -1 }
    }
    for i in 0 .. tree_count {
        e := tree_edges[i]; u := edge_u[e]; v := edge_v[e]
        adjacency[u * 9 + v] = e; adjacency[v * 9 + u] = e
    }
    for i in 0 .. pf_n + 1 { parent[i] = -2; parent_edge[i] = -2 }
    for i in 0 .. k { branch_root[i] = -1 }
    mut queue := [pf_n + 1]int{}
    mut head := 0; mut tail := 1
    parent[root] = -1; queue[0] = root
    for head < tail {
        u := queue[head]; head++
        for v in 0 .. k + 1 {
            if adjacency[u * 9 + v] != -2 && parent[v] == -2 {
                parent[v] = u; parent_edge[v] = adjacency[u * 9 + v]
                branch_root[v] = if u == root { v } else { branch_root[u] }
                queue[tail] = v; tail++
            }
        }
    }
    return tail == k + 1
}

fn pf_balance(k int, edge_count int, weight [pf_k]i64, edge_u [pf_m]int, edge_v [pf_m]int,
              flow [pf_m]i64, mut balance [pf_k]i64) {
    for v in 0 .. k { balance[v] = weight[v] }
    for e in 0 .. edge_count { balance[edge_u[e]] -= flow[e]; balance[edge_v[e]] += flow[e] }
}

fn pf_in_tree(tree_edges [pf_n]int, tree_count int, edge int) bool {
    for i in 0 .. tree_count { if tree_edges[i] == edge { return true } }
    return false
}

fn pf_remove_tree_edge(mut tree_edges [pf_n]int, mut tree_count int, edge int) bool {
    for i in 0 .. tree_count {
        if tree_edges[i] == edge {
            for j in i .. tree_count - 1 { tree_edges[j] = tree_edges[j + 1] }
            tree_count--
            return true
        }
    }
    return false
}

@[export: 'hochbaum_pseudoflow_maxflow']
pub fn hochbaum_pseudoflow_maxflow(input &i64, length usize) i64 {
    unsafe {
        if input == nil || length < 4 || length > 77 { return -1 }
        nv, mv, sr, tr := input[0], input[1], input[2], input[3]
        if nv < 2 || nv > 8 || mv < 0 || mv > 24 || sr < 1 || sr > nv || tr < 1 || tr > nv || sr == tr { return -1 }
        n, m, source, sink := int(nv), int(mv), int(sr - 1), int(tr - 1)
        if length != usize(4 + 3 * m) { return -1 }
        mut local := [pf_n]int{}
        for v in 0 .. n { local[v] = -1 }
        mut k := 0
        for v in 0 .. n { if v != source && v != sink { local[v] = k; k++ } }
        mut source_cap := [pf_k]i64{}
        mut sink_cap := [pf_k]i64{}
        mut direct_cap := i64(0)
        mut edge_u := [pf_m]int{}
        mut edge_v := [pf_m]int{}
        mut capacity := [pf_m]i64{}
        mut flow := [pf_m]i64{}
        mut edge_count := 0
        for i in 0 .. m {
            ur, vr, cap := input[4 + 3 * i], input[5 + 3 * i], input[6 + 3 * i]
            if ur < 1 || ur > nv || vr < 1 || vr > nv || ur == vr || cap < 0 || cap > 100 { return -1 }
            u, v := int(ur - 1), int(vr - 1)
            if u == source {
                if v == sink { direct_cap += cap } else { source_cap[local[v]] += cap }
            } else if v == sink { sink_cap[local[u]] += cap }
            else if v == source || u == sink { return -1 }
            else { edge_u[edge_count] = local[u]; edge_v[edge_count] = local[v]; capacity[edge_count] = cap; edge_count++ }
        }
        mut weight := [pf_k]i64{}
        mut balance := [pf_k]i64{}
        mut label := [pf_k]i64{}
        mut ticket := [pf_k]i64{}
        mut next_ticket := i64(0)
        mut root_edge := [pf_k]int{}
        mut tree_edges := [pf_n]int{}
        mut tree_count := 0
        for v in 0 .. k { weight[v] = source_cap[v] - sink_cap[v]; root_edge[v] = 1; label[v] = 1; ticket[v] = next_ticket; next_ticket++ }
        mut parent := [pf_n + 1]int{}
        mut parent_edge := [pf_n + 1]int{}
        mut branch_root := [pf_k]int{}
        for _ in 0 .. pf_iterations {
            pf_balance(k, edge_count, weight, edge_u, edge_v, flow, mut balance)
            if !pf_build_state(k, root_edge, tree_edges, tree_count, edge_u, edge_v, mut parent, mut parent_edge, mut branch_root) { return -1 }
            mut active := [pf_k]int{}
            mut strong := [pf_k]int{}
            old_label := label
            for r in 0 .. k { if root_edge[r] != 0 && balance[r] > 0 { active[r] = 1 } }
            for v in 0 .. k { strong[v] = if balance[branch_root[v]] > 0 { 1 } else { 0 } }
            mut crossing := false
            for e in 0 .. edge_count {
                u, v := edge_u[e], edge_v[e]
                if strong[u] != 0 && strong[v] == 0 && capacity[e] - flow[e] > 0 { crossing = true }
                if strong[v] != 0 && strong[u] == 0 && flow[e] > 0 { crossing = true }
            }
            if !crossing {
                mut cut := direct_cap
                for v in 0 .. k { if strong[v] != 0 { cut += sink_cap[v] } else { cut += source_cap[v] } }
                for e in 0 .. edge_count { if strong[edge_u[e]] != 0 && strong[edge_v[e]] == 0 { cut += capacity[e] } }
                if cut >= 0 && cut <= 2400 { return cut }
                return -1
            }
            mut strong_root := -1
            for r in 0 .. k {
                if active[r] != 0 && (strong_root < 0 || label[r] > label[strong_root] || (label[r] == label[strong_root] && ticket[r] < ticket[strong_root])) { strong_root = r }
            }
            if strong_root < 0 { return -1 }
            mut low := i64(1000)
            for v in 0 .. k { if branch_root[v] == strong_root && label[v] < low { low = label[v] } }
            mut tail := -1; mut head_node := -1; mut entering := -1
            for v in 0 .. k {
                if entering < 0 && branch_root[v] == strong_root && label[v] == low {
                    for e in 0 .. edge_count {
                        if entering < 0 && !pf_in_tree(tree_edges, tree_count, e) {
                            u, w := edge_u[e], edge_v[e]
                            if u == v && capacity[e] - flow[e] > 0 && branch_root[w] != strong_root && label[w] == low - 1 { tail = v; head_node = w; entering = e }
                            else if w == v && flow[e] > 0 && branch_root[u] != strong_root && label[u] == low - 1 { tail = v; head_node = u; entering = e }
                        }
                    }
                }
            }
            if entering < 0 {
                mut relabel := -1
                for v in 0 .. k {
                    if relabel < 0 && branch_root[v] == strong_root && label[v] == low {
                        mut children_ok := true
                        for child in 0 .. k { if parent[child] == v && label[child] < low + 1 { children_ok = false } }
                        if children_ok { relabel = v }
                    }
                }
                if relabel < 0 { return -1 }
                label[relabel]++
                if relabel == strong_root { ticket[strong_root] = next_ticket; next_ticket++ }
                continue
            }
            target_root := branch_root[head_node]
            root := k
            mut chain := [pf_n + 1]int{}
            mut chain_len := 0
            mut cursor := tail
            for cursor != root { chain[chain_len] = cursor; chain_len++; cursor = parent[cursor] }
            mut step_from := [2 * pf_n + 2]int{}
            mut step_to := [2 * pf_n + 2]int{}
            mut step_edge := [2 * pf_n + 2]int{}
            mut steps := 0
            mut j := chain_len - 1
            for j >= 0 {
                child := chain[j]
                if parent[child] != root { step_from[steps] = parent[child]; step_to[steps] = child; step_edge[steps] = parent_edge[child]; steps++ }
                j--
            }
            step_from[steps] = tail; step_to[steps] = head_node; step_edge[steps] = entering; steps++
            cursor = head_node
            for cursor != target_root { step_from[steps] = cursor; step_to[steps] = parent[cursor]; step_edge[steps] = parent_edge[cursor]; steps++; cursor = parent[cursor] }
            root_edge[strong_root] = 0
            tree_edges[tree_count] = entering
            tree_count++
            for j in 0 .. chain_len { label[chain[j]] = label[head_node] + 1 }
            mut carry := balance[strong_root]
            for j in 0 .. steps {
                e := step_edge[j]; u, v := edge_u[e], edge_v[e]
                residual := flow[e]
                if step_from[j] == u && step_to[j] == v { residual = capacity[e] - flow[e] }
                mut pushed := carry
                if residual < pushed { pushed = residual }
                if step_from[j] == u && step_to[j] == v { flow[e] += pushed } else { flow[e] -= pushed }
                if residual < carry {
                    if !pf_remove_tree_edge(mut tree_edges, mut tree_count, e) { return -1 }
                    root_edge[step_from[j]] = 1
                }
                carry = pushed
                if carry == 0 { break }
            }
            pf_balance(k, edge_count, weight, edge_u, edge_v, flow, mut balance)
            if !pf_build_state(k, root_edge, tree_edges, tree_count, edge_u, edge_v, mut parent, mut parent_edge, mut branch_root) { return -1 }
            for r in 0 .. k { if root_edge[r] != 0 && balance[r] > 0 && (active[r] == 0 || label[r] != old_label[r]) { ticket[r] = next_ticket; next_ticket++ } }
        }
        return -1
    }
}
