const MAX_N: usize = 8;
const MAX_M: usize = 28;
const MAX_INPUT: usize = 59;

unsafe fn put(out: *mut u8, at: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *out.add(at + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn khuller_raghavachari_three_edge_connected_spanning_subgraph(
    input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let n64 = *input;
    let m64 = *input.add(1);
    if !(4..=8).contains(&n64) || !(6..=28).contains(&m64)
        || length != 2 + 2 * m64 as usize { return -1; }
    let n = n64 as usize;
    let m = m64 as usize;
    let mut u = [0usize; MAX_M];
    let mut v = [0usize; MAX_M];
    for edge in 0..m {
        let a = *input.add(2 + 2 * edge);
        let b = *input.add(3 + 2 * edge);
        if a < 0 || a >= b || b >= n64 { return -1; }
        u[edge] = a as usize;
        v[edge] = b as usize;
        for prior in 0..edge {
            if u[prior] == u[edge] && v[prior] == v[edge] { return -1; }
        }
    }
    let full = (1usize << n) - 1;
    for side in 1..full {
        if (side & 1) == 0 { continue; }
        let cut = (0..m).filter(|&edge|
            ((side >> u[edge]) & 1) != ((side >> v[edge]) & 1)).count();
        if cut < 3 { return -1; }
    }

    let mut selected = [false; MAX_M];
    let mut state = [0usize; MAX_N];
    let mut discovery = [0usize; MAX_N];
    let mut finish = [0usize; MAX_N];
    let mut parent = [0usize; MAX_N];
    let mut parent_edge = [0usize; MAX_N];
    let mut postorder = [0usize; MAX_N];
    let mut stack_vertex = [0usize; MAX_N];
    let mut stack_slot = [0usize; MAX_N];
    let (mut post_count, mut clock, mut top) = (0, 1, 1);
    state[0] = 1; discovery[0] = 0; parent[0] = n; parent_edge[0] = m;
    stack_vertex[0] = 0;
    while top > 0 {
        let frame = top - 1;
        let x = stack_vertex[frame];
        if stack_slot[frame] < m {
            let edge = stack_slot[frame];
            stack_slot[frame] += 1;
            let y = if u[edge] == x { v[edge] } else if v[edge] == x { u[edge] } else { n };
            if y == n || state[y] != 0 { continue; }
            selected[edge] = true; state[y] = 1; parent[y] = x; parent_edge[y] = edge;
            discovery[y] = clock; clock += 1;
            stack_vertex[top] = y; stack_slot[top] = 0; top += 1;
            continue;
        }
        state[x] = 2; finish[x] = clock;
        if parent_edge[x] < m { postorder[post_count] = parent_edge[x]; post_count += 1; }
        top -= 1;
    }

    for position in 0..post_count {
        let tree_edge = postorder[position];
        let child = if parent_edge[u[tree_edge]] == tree_edge { u[tree_edge] } else { v[tree_edge] };
        let upper = parent[child];
        let mut separated = false;
        for removed in 0..m {
            if !selected[removed] { continue; }
            let mut seen = [false; MAX_N];
            let mut queue = [0usize; MAX_N];
            let (mut head, mut tail) = (0, 1);
            seen[upper] = true; queue[0] = upper;
            while head < tail {
                let current = queue[head]; head += 1;
                for edge in 0..m {
                    if !selected[edge] || edge == removed { continue; }
                    let next = if u[edge] == current { v[edge] }
                        else if v[edge] == current { u[edge] } else { n };
                    if next < n && !seen[next] { seen[next] = true; queue[tail] = next; tail += 1; }
                }
            }
            if !seen[child] { separated = true; break; }
        }
        if !separated { continue; }
        let (mut candidate, mut earliest) = (m, n);
        for edge in 0..m {
            if selected[edge] { continue; }
            let u_inside = discovery[child] <= discovery[u[edge]] && discovery[u[edge]] < finish[child];
            let v_inside = discovery[child] <= discovery[v[edge]] && discovery[v[edge]] < finish[child];
            if u_inside == v_inside { continue; }
            let ancestor = if u_inside { v[edge] } else { u[edge] };
            if discovery[ancestor] < earliest { earliest = discovery[ancestor]; candidate = edge; }
        }
        if candidate == m { return -1; }
        selected[candidate] = true;
    }

    let mut leader = [0usize; MAX_N];
    for vertex in 0..n { leader[vertex] = vertex; }
    for edge in 0..m {
        if selected[edge] { continue; }
        let (mut a, mut b) = (u[edge], v[edge]);
        while leader[a] != a { leader[a] = leader[leader[a]]; a = leader[a]; }
        while leader[b] != b { leader[b] = leader[leader[b]]; b = leader[b]; }
        if a != b { leader[b] = a; selected[edge] = true; }
    }
    let count = (0..m).filter(|&edge| selected[edge]).count();
    let bytes = 8 * (1 + 2 * count);
    if output.is_null() || capacity < bytes { return -2; }
    put(output, 0, count as i64);
    let mut slot = 0;
    for edge in 0..m {
        if !selected[edge] { continue; }
        put(output, 8 * (1 + 2 * slot), u[edge] as i64);
        put(output, 8 * (2 + 2 * slot), v[edge] as i64);
        slot += 1;
    }
    bytes as i64
}
