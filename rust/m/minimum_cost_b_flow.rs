const MAX_VERTICES: usize = 8;
const MAX_EDGES: usize = 10;
const MAX_ARCS: usize = 2 * MAX_EDGES + 2 * MAX_VERTICES;
const MAX_NODES: usize = MAX_VERTICES + 2;
const MAX_INPUT_LENGTH: usize = 2 + MAX_VERTICES + 5 * MAX_EDGES + 1;
const MAX_OUTPUT_WORDS: usize = 2 + MAX_VERTICES + MAX_EDGES;

struct ResidualGraph {
    from: [usize; MAX_ARCS],
    to: [usize; MAX_ARCS],
    reverse: [usize; MAX_ARCS],
    capacity: [i64; MAX_ARCS],
    cost: [i64; MAX_ARCS],
    arc_count: usize,
    original_arc_count: usize,
}

impl ResidualGraph {
    fn new() -> Self {
        Self { from: [0; MAX_ARCS], to: [0; MAX_ARCS], reverse: [0; MAX_ARCS],
            capacity: [0; MAX_ARCS], cost: [0; MAX_ARCS], arc_count: 0, original_arc_count: 0 }
    }

    fn add_edge(&mut self, from: usize, to: usize, capacity: i64, cost: i64) -> usize {
        let forward = self.arc_count;
        let backward = forward + 1;
        self.arc_count += 2;
        self.from[forward] = from; self.to[forward] = to;
        self.reverse[forward] = backward; self.capacity[forward] = capacity; self.cost[forward] = cost;
        self.from[backward] = to; self.to[backward] = from;
        self.reverse[backward] = forward; self.capacity[backward] = 0; self.cost[backward] = -cost;
        forward
    }

    fn feasible_flow(&mut self, vertex_count: usize, required_flow: i64) -> bool {
        let super_source = vertex_count;
        let super_sink = vertex_count + 1;
        let mut sent = 0;
        while sent < required_flow {
            let mut parent = [usize::MAX; MAX_NODES];
            let mut seen = [false; MAX_NODES];
            let mut queue = [0usize; MAX_NODES];
            let (mut head, mut length) = (0usize, 0usize);
            seen[super_source] = true; queue[length] = super_source; length += 1;
            while head < length {
                let vertex = queue[head]; head += 1;
                for edge in 0..self.arc_count {
                    let neighbor = self.to[edge];
                    if self.from[edge] == vertex && self.capacity[edge] > 0 && !seen[neighbor] {
                        seen[neighbor] = true; parent[neighbor] = edge; queue[length] = neighbor; length += 1;
                    }
                }
            }
            if !seen[super_sink] { return false; }
            let mut amount = required_flow - sent;
            let mut vertex = super_sink;
            while vertex != super_source {
                let edge = parent[vertex];
                amount = amount.min(self.capacity[edge]);
                vertex = self.from[edge];
            }
            vertex = super_sink;
            while vertex != super_source {
                let edge = parent[vertex];
                self.capacity[edge] -= amount;
                self.capacity[self.reverse[edge]] += amount;
                vertex = self.from[edge];
            }
            sent += amount;
        }
        true
    }

    fn cancel_negative_cycles(&mut self, vertex_count: usize) -> bool {
        if vertex_count == 0 { return true; }
        loop {
            let mut distance = [0i64; MAX_VERTICES];
            let mut parent = [usize::MAX; MAX_VERTICES];
            let mut changed_vertex = usize::MAX;
            for _ in 0..vertex_count {
                changed_vertex = usize::MAX;
                for edge in 0..self.original_arc_count {
                    let (from, to) = (self.from[edge], self.to[edge]);
                    if self.capacity[edge] > 0 && distance[to] > distance[from] + self.cost[edge] {
                        distance[to] = distance[from] + self.cost[edge];
                        parent[to] = edge;
                        changed_vertex = to;
                    }
                }
                if changed_vertex == usize::MAX { break; }
            }
            if changed_vertex == usize::MAX { return true; }
            let mut on_cycle = changed_vertex;
            for _ in 0..vertex_count {
                let edge = parent[on_cycle];
                if edge == usize::MAX { return false; }
                on_cycle = self.from[edge];
            }
            let mut amount = i64::MAX;
            let mut vertex = on_cycle;
            loop {
                let edge = parent[vertex];
                if edge == usize::MAX { return false; }
                amount = amount.min(self.capacity[edge]);
                vertex = self.from[edge];
                if vertex == on_cycle { break; }
            }
            vertex = on_cycle;
            loop {
                let edge = parent[vertex];
                self.capacity[edge] -= amount;
                self.capacity[self.reverse[edge]] += amount;
                vertex = self.from[edge];
                if vertex == on_cycle { break; }
            }
        }
    }
}

fn solve(n: usize, m: usize, values: &[i64], words: &mut [i64; MAX_OUTPUT_WORDS]) -> bool {
    let edge_offset = 2 + n;
    let mut required = [0i64; MAX_VERTICES];
    required[..n].copy_from_slice(&values[2..2 + n]);
    for edge in 0..m {
        let offset = edge_offset + 5 * edge;
        let (from, to, lower) = (values[offset] as usize, values[offset + 1] as usize, values[offset + 2]);
        required[from] -= lower; required[to] += lower;
    }
    let mut required_flow = 0;
    if required[..n].iter().sum::<i64>() != 0 { return false; }
    for &balance in &required[..n] { if balance > 0 { required_flow += balance; } }
    let mut graph = ResidualGraph::new();
    for edge in 0..m {
        let offset = edge_offset + 5 * edge;
        graph.add_edge(values[offset] as usize, values[offset + 1] as usize,
            values[offset + 3] - values[offset + 2], values[offset + 4]);
    }
    graph.original_arc_count = graph.arc_count;
    for (vertex, &balance) in required[..n].iter().enumerate() {
        if balance > 0 { graph.add_edge(n, vertex, balance, 0); }
        else if balance < 0 { graph.add_edge(vertex, n + 1, -balance, 0); }
    }
    if !graph.feasible_flow(n, required_flow) || !graph.cancel_negative_cycles(n) { return false; }
    let mut potential = [0i64; MAX_VERTICES];
    for _ in 0..n.saturating_sub(1) {
        let mut changed = false;
        for edge in 0..graph.original_arc_count {
            let (from, to) = (graph.from[edge], graph.to[edge]);
            if graph.capacity[edge] > 0 && potential[to] > potential[from] + graph.cost[edge] {
                potential[to] = potential[from] + graph.cost[edge];
                changed = true;
            }
        }
        if !changed { break; }
    }
    words[0] = 1; words[1] = 0;
    words[2..2 + n].copy_from_slice(&potential[..n]);
    for edge in 0..m {
        let offset = edge_offset + 5 * edge;
        let flow = values[offset + 3] - graph.capacity[2 * edge];
        words[2 + n + edge] = flow;
        words[1] += flow * values[offset + 4];
    }
    true
}

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    unsafe { std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(offset), 8); }
}

#[no_mangle]
pub unsafe extern "C" fn minimum_cost_b_flow(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (raw_n, raw_m) = (values[0], values[1]);
    if !(0..=MAX_VERTICES as i64).contains(&raw_n) || !(0..=MAX_EDGES as i64).contains(&raw_m) { return -1; }
    let (n, m) = (raw_n as usize, raw_m as usize);
    if length != 2 + n + 5 * m { return -1; }
    for &balance in &values[2..2 + n] { if !(-5..=5).contains(&balance) { return -1; } }
    let edge_offset = 2 + n;
    for edge in 0..m {
        let offset = edge_offset + 5 * edge;
        let (from, to, lower, upper, cost) = (values[offset], values[offset + 1], values[offset + 2], values[offset + 3], values[offset + 4]);
        if from < 0 || from >= raw_n || to < 0 || to >= raw_n || lower < -3 || upper > 3 ||
            lower > upper || upper - lower > 2 || !(-4..=4).contains(&cost) { return -1; }
    }
    let output_words = 2 + n + m;
    let output_bytes = 8 * output_words;
    if output.is_null() || output_capacity < output_bytes { return -2; }
    let mut words = [0i64; MAX_OUTPUT_WORDS];
    if !solve(n, m, values, &mut words) { words.fill(0); }
    for word in 0..output_words { store_i64_le(output, 8 * word, words[word]); }
    output_bytes as i64
}
