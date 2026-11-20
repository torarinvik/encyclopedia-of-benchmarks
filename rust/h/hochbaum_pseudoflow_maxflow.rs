const PF_N: usize = 8;
const PF_K: usize = 6;
const PF_M: usize = 24;
const PF_ITERATIONS: usize = 512;

fn build_state(k: usize, root_edge: &[bool; PF_K], tree_edges: &[usize; PF_N], tree_count: usize,
               edge_u: &[usize; PF_M], edge_v: &[usize; PF_M], parent: &mut [i32; PF_N + 1],
               parent_edge: &mut [i32; PF_N + 1], branch_root: &mut [i32; PF_K]) -> bool {
    let root = k;
    let mut adjacency = [[-2i32; PF_N + 1]; PF_N + 1];
    for v in 0..k { if root_edge[v] { adjacency[root][v] = -1; adjacency[v][root] = -1; } }
    for i in 0..tree_count {
        let e = tree_edges[i]; let (u, v) = (edge_u[e], edge_v[e]);
        adjacency[u][v] = e as i32; adjacency[v][u] = e as i32;
    }
    parent.fill(-2); parent_edge.fill(-2); branch_root.fill(-1);
    let mut queue = [0usize; PF_N + 1]; let (mut head, mut tail) = (0usize, 1usize);
    parent[root] = -1; queue[0] = root;
    while head < tail {
        let u = queue[head]; head += 1;
        for v in 0..=k {
            if adjacency[u][v] == -2 || parent[v] != -2 { continue; }
            parent[v] = u as i32; parent_edge[v] = adjacency[u][v];
            branch_root[v] = if u == root { v as i32 } else { branch_root[u] };
            queue[tail] = v; tail += 1;
        }
    }
    tail == k + 1
}

fn calculate_balance(k: usize, edge_count: usize, weight: &[i64; PF_K], edge_u: &[usize; PF_M],
                     edge_v: &[usize; PF_M], flow: &[i64; PF_M], balance: &mut [i64; PF_K]) {
    for v in 0..k { balance[v] = weight[v]; }
    for e in 0..edge_count { balance[edge_u[e]] -= flow[e]; balance[edge_v[e]] += flow[e]; }
}

fn in_tree(tree_edges: &[usize; PF_N], tree_count: usize, edge: usize) -> bool {
    (0..tree_count).any(|i| tree_edges[i] == edge)
}

fn remove_tree_edge(tree_edges: &mut [usize; PF_N], tree_count: &mut usize, edge: usize) -> bool {
    for i in 0..*tree_count {
        if tree_edges[i] == edge {
            for j in i..(*tree_count - 1) { tree_edges[j] = tree_edges[j + 1]; }
            *tree_count -= 1;
            return true;
        }
    }
    false
}

#[no_mangle]
pub unsafe extern "C" fn hochbaum_pseudoflow_maxflow(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(4..=77).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (nv, mv, source_raw, sink_raw) = (values[0], values[1], values[2], values[3]);
    if !(2..=8).contains(&nv) || !(0..=24).contains(&mv) || source_raw < 1 || source_raw > nv ||
        sink_raw < 1 || sink_raw > nv || source_raw == sink_raw { return -1; }
    let (n, m, source, sink) = (nv as usize, mv as usize, (source_raw - 1) as usize, (sink_raw - 1) as usize);
    if length != 4 + 3*m { return -1; }
    let mut local = [-1i32; PF_N]; let mut k = 0usize;
    for v in 0..n { if v != source && v != sink { local[v] = k as i32; k += 1; } }
    let mut source_cap = [0i64; PF_K]; let mut sink_cap = [0i64; PF_K]; let mut direct_cap = 0i64;
    let mut edge_u = [0usize; PF_M]; let mut edge_v = [0usize; PF_M];
    let mut capacity = [0i64; PF_M]; let mut flow = [0i64; PF_M]; let mut edge_count = 0usize;
    for i in 0..m {
        let (ur, vr, cap) = (values[4+3*i], values[5+3*i], values[6+3*i]);
        if ur < 1 || ur > nv || vr < 1 || vr > nv || ur == vr || !(0..=100).contains(&cap) { return -1; }
        let (u, v) = ((ur-1) as usize, (vr-1) as usize);
        if u == source { if v == sink { direct_cap += cap; } else { source_cap[local[v] as usize] += cap; } }
        else if v == sink { sink_cap[local[u] as usize] += cap; }
        else if v == source || u == sink { return -1; }
        else { edge_u[edge_count] = local[u] as usize; edge_v[edge_count] = local[v] as usize; capacity[edge_count] = cap; edge_count += 1; }
    }
    let mut weight = [0i64; PF_K]; let mut balance = [0i64; PF_K];
    let mut label = [0i64; PF_K]; let mut ticket = [0i64; PF_K]; let mut next_ticket = 0i64;
    let mut root_edge = [false; PF_K]; let mut tree_edges = [0usize; PF_N]; let mut tree_count = 0usize;
    for v in 0..k { weight[v] = source_cap[v] - sink_cap[v]; root_edge[v] = true; label[v] = 1; ticket[v] = next_ticket; next_ticket += 1; }
    let mut parent = [-2i32; PF_N+1]; let mut parent_edge = [-2i32; PF_N+1]; let mut branch_root = [-1i32; PF_K];

    for _iteration in 0..PF_ITERATIONS {
        calculate_balance(k, edge_count, &weight, &edge_u, &edge_v, &flow, &mut balance);
        if !build_state(k, &root_edge, &tree_edges, tree_count, &edge_u, &edge_v, &mut parent, &mut parent_edge, &mut branch_root) { return -1; }
        let mut active = [false; PF_K]; let mut strong = [false; PF_K]; let old_label = label;
        for r in 0..k { active[r] = root_edge[r] && balance[r] > 0; }
        for v in 0..k { strong[v] = balance[branch_root[v] as usize] > 0; }
        let mut crossing = false;
        for e in 0..edge_count {
            if strong[edge_u[e]] && !strong[edge_v[e]] && capacity[e] - flow[e] > 0 { crossing = true; }
            if strong[edge_v[e]] && !strong[edge_u[e]] && flow[e] > 0 { crossing = true; }
        }
        if !crossing {
            let mut cut = direct_cap;
            for v in 0..k { cut += if strong[v] { sink_cap[v] } else { source_cap[v] }; }
            for e in 0..edge_count { if strong[edge_u[e]] && !strong[edge_v[e]] { cut += capacity[e]; } }
            return if (0..=2400).contains(&cut) { cut } else { -1 };
        }
        let mut strong_root = None;
        for r in 0..k { if active[r] && strong_root.map_or(true, |old| label[r] > label[old] || (label[r] == label[old] && ticket[r] < ticket[old])) { strong_root = Some(r); } }
        let Some(sr) = strong_root else { return -1; };
        let mut low = i64::MAX;
        for v in 0..k { if branch_root[v] as usize == sr { low = low.min(label[v]); } }
        let mut found = None;
        'search: for tail in 0..k {
            if branch_root[tail] as usize != sr || label[tail] != low { continue; }
            for e in 0..edge_count {
                if in_tree(&tree_edges, tree_count, e) { continue; }
                if edge_u[e] == tail && capacity[e] - flow[e] > 0 && branch_root[edge_v[e]] as usize != sr && label[edge_v[e]] == low - 1 {
                    found = Some((tail, e, edge_v[e])); break 'search;
                }
                if edge_v[e] == tail && flow[e] > 0 && branch_root[edge_u[e]] as usize != sr && label[edge_u[e]] == low - 1 {
                    found = Some((tail, e, edge_u[e])); break 'search;
                }
            }
        }
        let Some((tail, entering, head)) = found else {
            let mut relabel = None;
            for v in 0..k {
                if branch_root[v] as usize == sr && label[v] == low {
                    let mut children_ok = true;
                    for child in 0..k { if parent[child] == v as i32 && label[child] < low + 1 { children_ok = false; } }
                    if children_ok { relabel = Some(v); break; }
                }
            }
            let Some(v) = relabel else { return -1; };
            label[v] += 1;
            if v == sr { ticket[sr] = next_ticket; next_ticket += 1; }
            continue;
        };
        let target_root = branch_root[head] as usize; let root = k;
        let mut chain = [0usize; PF_N+1]; let mut chain_len = 0usize; let mut cursor = tail;
        while cursor != root { chain[chain_len] = cursor; chain_len += 1; cursor = parent[cursor] as usize; }
        let mut step_from = [0usize; 2*PF_N+2]; let mut step_to = [0usize; 2*PF_N+2];
        let mut step_edge = [0usize; 2*PF_N+2]; let mut steps = 0usize;
        for j in (0..chain_len).rev() { let child=chain[j]; if parent[child] as usize != root { step_from[steps]=parent[child] as usize; step_to[steps]=child; step_edge[steps]=parent_edge[child] as usize; steps+=1; } }
        step_from[steps]=tail; step_to[steps]=head; step_edge[steps]=entering; steps+=1;
        cursor=head;
        while cursor != target_root { step_from[steps]=cursor; step_to[steps]=parent[cursor] as usize; step_edge[steps]=parent_edge[cursor] as usize; steps+=1; cursor=parent[cursor] as usize; }
        root_edge[sr]=false; tree_edges[tree_count]=entering; tree_count+=1;
        for j in 0..chain_len { label[chain[j]]=label[head]+1; }
        let mut carry=balance[sr];
        for j in 0..steps {
            let e=step_edge[j]; let (u,v)=(edge_u[e],edge_v[e]);
            let residual=if step_from[j]==u && step_to[j]==v { capacity[e]-flow[e] } else { flow[e] };
            let pushed=carry.min(residual);
            if step_from[j]==u && step_to[j]==v { flow[e]+=pushed; } else { flow[e]-=pushed; }
            if residual<carry { if !remove_tree_edge(&mut tree_edges,&mut tree_count,e) { return -1; } root_edge[step_from[j]]=true; }
            carry=pushed;
            if carry==0 { break; }
        }
        calculate_balance(k, edge_count, &weight, &edge_u, &edge_v, &flow, &mut balance);
        if !build_state(k, &root_edge, &tree_edges, tree_count, &edge_u, &edge_v, &mut parent, &mut parent_edge, &mut branch_root) { return -1; }
        for r in 0..k { if root_edge[r] && balance[r]>0 && (!active[r] || label[r]!=old_label[r]) { ticket[r]=next_ticket; next_ticket+=1; } }
    }
    -1
}
