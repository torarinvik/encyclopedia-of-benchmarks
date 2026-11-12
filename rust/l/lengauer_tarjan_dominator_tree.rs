const MAX_V: usize = 63;
const MAX_E: usize = 2047;
const MAX_INPUT: usize = 4097;

fn evaluate(
    vertex: usize,
    ancestor: &mut [i32; MAX_V + 1],
    label: &mut [i32; MAX_V + 1],
    semi: &[i32; MAX_V + 1],
    path: &mut [i32; MAX_V + 1],
) -> usize {
    if ancestor[vertex] == 0 { return vertex; }
    let mut used = 0usize;
    let mut current = vertex;
    while ancestor[ancestor[current] as usize] != 0 {
        path[used] = current as i32;
        used += 1;
        current = ancestor[current] as usize;
    }
    while used > 0 {
        used -= 1;
        current = path[used] as usize;
        let parent = ancestor[current] as usize;
        if semi[label[parent] as usize] < semi[label[current] as usize] {
            label[current] = label[parent];
        }
        ancestor[current] = ancestor[parent];
    }
    label[vertex] as usize
}

#[no_mangle]
pub unsafe extern "C" fn lengauer_tarjan_dominator_tree(
    input_ptr: *const i64,
    length: usize,
    output_ptr: *mut u8,
    capacity: usize,
) -> i64 {
    if input_ptr.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let input = std::slice::from_raw_parts(input_ptr, length);
    let (nv, root_value, me) = (input[0], input[1], input[2]);
    if nv < 1 || nv > MAX_V as i64 || root_value < 0 || root_value >= nv ||
        me < 0 || me > MAX_E as i64 { return -1; }
    let (n, root, m) = (nv as usize, root_value as usize, me as usize);
    if length != 3 + 2 * m { return -1; }

    let mut outmask = [0u64; MAX_V];
    let mut out_head = [-1i32; MAX_V];
    let mut edge_source = [0i32; MAX_E];
    let mut edge_target = [0i32; MAX_E];
    let mut out_next = [-1i32; MAX_E];
    let mut pred_head = [-1i32; MAX_V + 1];
    let mut pred_next = [-1i32; MAX_E];
    let mut dfs_number = [0i32; MAX_V];
    let mut vertex_at = [0i32; MAX_V + 1];
    let mut parent = [0i32; MAX_V + 1];
    let mut semi = [0i32; MAX_V + 1];
    let mut ancestor = [0i32; MAX_V + 1];
    let mut label = [0i32; MAX_V + 1];
    let mut immediate = [0i32; MAX_V + 1];
    let mut bucket_head = [-1i32; MAX_V + 1];
    let mut bucket_next = [0i32; MAX_V + 1];
    let mut node_stack = [0usize; MAX_V];
    let mut edge_stack = [-1i32; MAX_V];
    let mut eval_path = [0i32; MAX_V + 1];
    let mut staged = [0u8; MAX_V];

    let mut edge_count = 0usize;
    for i in 0..m {
        let (sv, tv) = (input[3 + 2 * i], input[4 + 2 * i]);
        if sv < 0 || sv >= nv || tv < 0 || tv >= nv { return -1; }
        let (source, target) = (sv as usize, tv as usize);
        let bit = 1u64 << target;
        if outmask[source] & bit == 0 {
            outmask[source] |= bit;
            edge_source[edge_count] = source as i32;
            edge_target[edge_count] = target as i32;
            out_next[edge_count] = out_head[source];
            out_head[source] = edge_count as i32;
            edge_count += 1;
        }
    }

    let (mut dfs_count, mut top) = (1usize, 1usize);
    dfs_number[root] = 1;
    vertex_at[1] = root as i32;
    node_stack[0] = root;
    edge_stack[0] = out_head[root];
    while top > 0 {
        let frame = top - 1;
        let current = node_stack[frame];
        let edge = edge_stack[frame];
        if edge == -1 { top -= 1; continue; }
        edge_stack[frame] = out_next[edge as usize];
        let target = edge_target[edge as usize] as usize;
        if dfs_number[target] == 0 {
            dfs_count += 1;
            dfs_number[target] = dfs_count as i32;
            vertex_at[dfs_count] = target as i32;
            parent[dfs_count] = dfs_number[current];
            node_stack[top] = target;
            edge_stack[top] = out_head[target];
            top += 1;
        }
    }

    for edge in 0..edge_count {
        let source_number = dfs_number[edge_source[edge] as usize];
        let target_number = dfs_number[edge_target[edge] as usize];
        if source_number != 0 && target_number != 0 {
            pred_next[edge] = pred_head[target_number as usize];
            pred_head[target_number as usize] = edge as i32;
        }
    }
    for vertex in 1..=dfs_count {
        semi[vertex] = vertex as i32;
        label[vertex] = vertex as i32;
    }

    for w in (2..=dfs_count).rev() {
        let mut edge = pred_head[w];
        while edge != -1 {
            let index = edge as usize;
            let predecessor = dfs_number[edge_source[index] as usize] as usize;
            let representative = evaluate(predecessor, &mut ancestor, &mut label, &semi, &mut eval_path);
            if semi[representative] < semi[w] { semi[w] = semi[representative]; }
            edge = pred_next[index];
        }
        bucket_next[w] = bucket_head[semi[w] as usize];
        bucket_head[semi[w] as usize] = w as i32;
        ancestor[w] = parent[w];
        let owner = parent[w] as usize;
        let mut member = bucket_head[owner];
        bucket_head[owner] = -1;
        while member != -1 {
            let vertex = member as usize;
            let next = bucket_next[vertex];
            let representative = evaluate(vertex, &mut ancestor, &mut label, &semi, &mut eval_path);
            immediate[vertex] = if semi[representative] < semi[vertex] {
                representative as i32
            } else { owner as i32 };
            member = next;
        }
    }
    for w in 2..=dfs_count {
        if immediate[w] != semi[w] {
            immediate[w] = immediate[immediate[w] as usize];
        }
    }
    immediate[1] = 1;

    for vertex in 0..n {
        let number = dfs_number[vertex];
        staged[vertex] = if number == 0 { 255 } else {
            vertex_at[immediate[number as usize] as usize] as u8
        };
    }
    if output_ptr.is_null() || capacity < n { return -2; }
    std::slice::from_raw_parts_mut(output_ptr, n).copy_from_slice(&staged[..n]);
    n as i64
}
