const MAX_N: usize = 6;
const MAX_M: usize = 8;
const MAX_INPUT: usize = 35;
const NODE_CAP: usize = 8;

fn execute(input: &[i64]) -> Option<i64> {
    if input.len() < 2 || input.len() > MAX_INPUT { return None; }
    let n_value = input[0];
    let m_value = input[1];
    if n_value < 1 || n_value > MAX_N as i64 || m_value < 0 || m_value > MAX_M as i64 {
        return None;
    }
    let n = n_value as usize;
    let m = m_value as usize;
    if input.len() != 2 + 4 * m { return None; }

    let mut residual = [0i64; NODE_CAP * NODE_CAP];
    let mut balance = [0i64; MAX_N];
    for index in 0..m {
        let offset = 2 + 4 * index;
        let (u_value, v_value) = (input[offset], input[offset + 1]);
        let (lower, upper) = (input[offset + 2], input[offset + 3]);
        if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value
            || lower < 0 || upper < lower || upper > 2 { return None; }
        let (u, v) = (u_value as usize, v_value as usize);
        residual[u * NODE_CAP + v] += upper - lower;
        balance[u] -= lower;
        balance[v] += lower;
    }

    let source = n;
    let sink = n + 1;
    let node_count = n + 2;
    let mut demand = 0i64;
    for vertex in 0..n {
        if balance[vertex] > 0 {
            residual[source * NODE_CAP + vertex] += balance[vertex];
            demand += balance[vertex];
        } else if balance[vertex] < 0 {
            residual[vertex * NODE_CAP + sink] += -balance[vertex];
        }
    }

    let mut flow = 0i64;
    while flow < demand {
        let mut parent = [-1isize; NODE_CAP];
        let mut queue = [0usize; NODE_CAP];
        let (mut head, mut tail) = (0usize, 0usize);
        parent[source] = source as isize;
        queue[tail] = source;
        tail += 1;
        while head < tail && parent[sink] < 0 {
            let u = queue[head];
            head += 1;
            for v in 0..node_count {
                if residual[u * NODE_CAP + v] > 0 && parent[v] < 0 {
                    parent[v] = u as isize;
                    queue[tail] = v;
                    tail += 1;
                    if v == sink { break; }
                }
            }
        }
        if parent[sink] < 0 { break; }
        let mut amount = demand - flow;
        let mut vertex = sink;
        while vertex != source {
            let u = parent[vertex] as usize;
            amount = amount.min(residual[u * NODE_CAP + vertex]);
            vertex = u;
        }
        vertex = sink;
        while vertex != source {
            let u = parent[vertex] as usize;
            residual[u * NODE_CAP + vertex] -= amount;
            residual[vertex * NODE_CAP + u] += amount;
            vertex = u;
        }
        flow += amount;
    }
    Some(if flow == demand { 1 } else { 0 })
}

#[no_mangle]
pub unsafe extern "C" fn lower_bound_circulation_feasibility(input: *const i64,
                                                               length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    execute(values).unwrap_or(-1)
}
