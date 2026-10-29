const MAX_VERTICES: usize = 8;
const MAX_EDGES: usize = 28;
const MAX_ARCS: usize = 2 * MAX_EDGES;
const MAX_INPUT: usize = 4 + 2 * MAX_EDGES;

/// Return an Even-Tarjan st-numbering as one rank byte per vertex.
#[no_mangle]
pub unsafe extern "C" fn st_numbering(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 4 || input_length > MAX_INPUT {
        return -1;
    }
    let input = std::slice::from_raw_parts(input, input_length);
    let n_value = input[0];
    let m_value = input[1];
    let s_value = input[2];
    let t_value = input[3];
    if !(2..=MAX_VERTICES as i64).contains(&n_value)
        || !(0..=MAX_EDGES as i64).contains(&m_value)
        || s_value < 0
        || s_value >= n_value
        || t_value < 0
        || t_value >= n_value
        || s_value == t_value
        || input_length != 4 + 2 * m_value as usize
    {
        return -1;
    }
    let (n, m, s, t) = (n_value as usize, m_value as usize, s_value as usize, t_value as usize);

    let mut edge_u = [0usize; MAX_EDGES];
    let mut edge_v = [0usize; MAX_EDGES];
    let mut adjacent = [0u16; MAX_VERTICES];
    let mut st_edge = usize::MAX;
    for edge in 0..m {
        let u_value = input[4 + 2 * edge];
        let v_value = input[5 + 2 * edge];
        if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value {
            return -1;
        }
        let (u, v) = (u_value as usize, v_value as usize);
        if adjacent[u] & (1u16 << v) != 0 {
            return -1;
        }
        adjacent[u] |= 1u16 << v;
        adjacent[v] |= 1u16 << u;
        edge_u[edge] = u;
        edge_v[edge] = v;
        if (u == s && v == t) || (u == t && v == s) {
            st_edge = edge;
        }
    }
    if st_edge == usize::MAX {
        return -1;
    }

    let mut head = [-1i32; MAX_VERTICES];
    let mut arc_to = [0usize; MAX_ARCS];
    let mut arc_next = [-1i32; MAX_ARCS];
    let mut arc_count = 0usize;
    for edge in 0..m {
        if edge == st_edge { continue; }
        let (u, v) = (edge_u[edge], edge_v[edge]);
        arc_to[arc_count] = v;
        arc_next[arc_count] = head[u];
        head[u] = arc_count as i32;
        arc_count += 1;
        arc_to[arc_count] = u;
        arc_next[arc_count] = head[v];
        head[v] = arc_count as i32;
        arc_count += 1;
    }
    arc_to[arc_count] = t;
    arc_next[arc_count] = head[s];
    head[s] = arc_count as i32;
    arc_count += 1;
    arc_to[arc_count] = s;
    arc_next[arc_count] = head[t];
    head[t] = arc_count as i32;

    let mut parent = [-1i32; MAX_VERTICES];
    let mut discovery = [0usize; MAX_VERTICES];
    let mut low_vertex = [0usize; MAX_VERTICES];
    let mut children = [0usize; MAX_VERTICES];
    let mut next_arc = [-1i32; MAX_VERTICES];
    let mut preorder = [0usize; MAX_VERTICES];
    let mut stack = [0usize; MAX_VERTICES];
    let (mut top, mut clock, mut preorder_count) = (0usize, 1usize, 1usize);
    discovery[s] = clock;
    low_vertex[s] = s;
    preorder[0] = s;
    next_arc[s] = head[s];
    stack[top] = s;
    top += 1;
    while top > 0 {
        let vertex = stack[top - 1];
        let arc = next_arc[vertex];
        if arc < 0 {
            top -= 1;
            let ancestor = parent[vertex];
            if ancestor >= 0 {
                let ancestor = ancestor as usize;
                if discovery[low_vertex[vertex]] < discovery[low_vertex[ancestor]] {
                    low_vertex[ancestor] = low_vertex[vertex];
                }
            }
            continue;
        }
        let arc = arc as usize;
        next_arc[vertex] = arc_next[arc];
        let neighbor = arc_to[arc];
        if parent[vertex] >= 0 && neighbor == parent[vertex] as usize {
            continue;
        }
        if discovery[neighbor] == 0 {
            parent[neighbor] = vertex as i32;
            children[vertex] += 1;
            clock += 1;
            discovery[neighbor] = clock;
            low_vertex[neighbor] = neighbor;
            preorder[preorder_count] = neighbor;
            preorder_count += 1;
            next_arc[neighbor] = head[neighbor];
            stack[top] = neighbor;
            top += 1;
        } else if discovery[neighbor] < discovery[vertex]
            && discovery[neighbor] < discovery[low_vertex[vertex]]
        {
            low_vertex[vertex] = neighbor;
        }
    }
    if preorder_count != n || children[s] != 1 {
        return -1;
    }
    for vertex in 0..n {
        if vertex == s { continue; }
        for child in 0..n {
            if parent[child] == vertex as i32 && discovery[low_vertex[child]] >= discovery[vertex] {
                return -1;
            }
        }
    }

    let mut previous = [-1i32; MAX_VERTICES];
    let mut following = [-1i32; MAX_VERTICES];
    let mut sign = [0i8; MAX_VERTICES];
    sign[s] = -1;
    following[s] = t as i32;
    previous[t] = s as i32;
    let mut list_head = s;
    for order in 2..n {
        let vertex = preorder[order];
        let ancestor = parent[vertex] as usize;
        if sign[low_vertex[vertex]] == -1 {
            let left = previous[ancestor];
            previous[vertex] = left;
            following[vertex] = ancestor as i32;
            previous[ancestor] = vertex as i32;
            if left >= 0 {
                following[left as usize] = vertex as i32;
            } else {
                list_head = vertex;
            }
            sign[ancestor] = 1;
        } else {
            let right = following[ancestor];
            previous[vertex] = ancestor as i32;
            following[vertex] = right;
            following[ancestor] = vertex as i32;
            if right >= 0 {
                previous[right as usize] = vertex as i32;
            }
            sign[ancestor] = -1;
        }
    }

    let mut rank = [0usize; MAX_VERTICES];
    let mut staged = [0u8; MAX_VERTICES];
    let (mut rank_value, mut vertex) = (1usize, list_head as i32);
    while vertex >= 0 && rank_value <= n {
        let current = vertex as usize;
        rank[current] = rank_value;
        staged[current] = rank_value as u8;
        rank_value += 1;
        vertex = following[current];
    }
    if rank_value != n + 1 || rank[s] != 1 || rank[t] != n {
        return -1;
    }
    for v in 0..n {
        if v == s || v == t { continue; }
        let (mut lower, mut higher) = (false, false);
        let mut arc = head[v];
        while arc >= 0 {
            let neighbor = arc_to[arc as usize];
            lower |= rank[neighbor] < rank[v];
            higher |= rank[neighbor] > rank[v];
            arc = arc_next[arc as usize];
        }
        if !lower || !higher {
            return -1;
        }
    }
    if output.is_null() || output_capacity < n {
        return -2;
    }
    std::slice::from_raw_parts_mut(output, n).copy_from_slice(&staged[..n]);
    n as i64
}
