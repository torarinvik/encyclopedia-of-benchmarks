const MAX_N: usize = 6;
const MAX_M: usize = 8;
const MAX_INPUT: usize = 37;
const NODE_CAP: usize = 8;

fn feasible(input: &[i64], n: usize, m: usize, source: usize, sink: usize,
            flow_cap: i64) -> bool {
    let mut residual = [0i64; NODE_CAP * NODE_CAP];
    let mut balance = [0i64; MAX_N];
    for index in 0..m {
        let offset = 4 + 4 * index;
        let u = input[offset] as usize;
        let v = input[offset + 1] as usize;
        let lower = input[offset + 2];
        let upper = input[offset + 3];
        residual[u * NODE_CAP + v] += upper - lower;
        balance[u] -= lower;
        balance[v] += lower;
    }
    residual[sink * NODE_CAP + source] += flow_cap;

    let super_source = n;
    let super_sink = n + 1;
    let node_count = n + 2;
    let mut demand = 0i64;
    for vertex in 0..n {
        if balance[vertex] > 0 {
            residual[super_source * NODE_CAP + vertex] += balance[vertex];
            demand += balance[vertex];
        } else if balance[vertex] < 0 {
            residual[vertex * NODE_CAP + super_sink] += -balance[vertex];
        }
    }

    let mut flow = 0i64;
    while flow < demand {
        let mut parent = [-1isize; NODE_CAP];
        let mut queue = [0usize; NODE_CAP];
        let (mut head, mut tail) = (0usize, 0usize);
        parent[super_source] = super_source as isize;
        queue[tail] = super_source;
        tail += 1;
        while head < tail && parent[super_sink] < 0 {
            let u = queue[head];
            head += 1;
            for v in 0..node_count {
                if residual[u * NODE_CAP + v] > 0 && parent[v] < 0 {
                    parent[v] = u as isize;
                    queue[tail] = v;
                    tail += 1;
                    if v == super_sink { break; }
                }
            }
        }
        if parent[super_sink] < 0 { break; }
        let mut amount = demand - flow;
        let mut vertex = super_sink;
        while vertex != super_source {
            let u = parent[vertex] as usize;
            amount = amount.min(residual[u * NODE_CAP + vertex]);
            vertex = u;
        }
        vertex = super_sink;
        while vertex != super_source {
            let u = parent[vertex] as usize;
            residual[u * NODE_CAP + vertex] -= amount;
            residual[vertex * NODE_CAP + u] += amount;
            vertex = u;
        }
        flow += amount;
    }
    flow == demand
}

fn execute(input: &[i64]) -> Option<i64> {
    if input.len() < 4 || input.len() > MAX_INPUT { return None; }
    let n_value = input[0];
    let m_value = input[1];
    let source_value = input[2];
    let sink_value = input[3];
    if n_value < 2 || n_value > MAX_N as i64 || m_value < 0 || m_value > MAX_M as i64 {
        return None;
    }
    if source_value < 0 || source_value >= n_value || sink_value < 0 ||
        sink_value >= n_value || source_value == sink_value { return None; }
    let n = n_value as usize;
    let m = m_value as usize;
    let source = source_value as usize;
    let sink = sink_value as usize;
    if input.len() != 4 + 4 * m { return None; }

    let mut upper_bound = 0i64;
    for index in 0..m {
        let offset = 4 + 4 * index;
        let (u, v) = (input[offset], input[offset + 1]);
        let (lower, upper) = (input[offset + 2], input[offset + 3]);
        if u < 0 || u >= n_value || v < 0 || v >= n_value || lower < 0 ||
            upper < lower || upper > 2 { return None; }
        if u as usize == source && v as usize != source { upper_bound += upper; }
    }

    let mut low = 0i64;
    let mut high = upper_bound + 1;
    while low < high {
        let middle = low + (high - low) / 2;
        if feasible(input, n, m, source, sink, middle) { high = middle; }
        else { low = middle + 1; }
    }
    Some(if low > upper_bound { -2 } else { low })
}

#[no_mangle]
pub unsafe extern "C" fn minimum_bounded_s_t_flow(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    execute(values).unwrap_or(-1)
}
