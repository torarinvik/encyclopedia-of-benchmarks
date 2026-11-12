const MAX_VERTICES: usize = 64;
const MAX_EDGES: usize = 128;
const MAX_ARCS: usize = 2 * MAX_EDGES;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_EDGES + 1;

struct Graph {
    head: [i32; MAX_VERTICES],
    tail: [i32; MAX_VERTICES],
    to: [i32; MAX_ARCS],
    next: [i32; MAX_ARCS],
    arc_edge: [i32; MAX_ARCS],
    edge_u: [i32; MAX_EDGES],
    edge_used: [bool; MAX_EDGES],
    direction: [i32; MAX_EDGES],
    discovery: [i32; MAX_VERTICES],
    low: [i32; MAX_VERTICES],
    timer: i32,
    bridges: i32,
}

impl Graph {
    fn new() -> Self {
        Self {
            head: [-1; MAX_VERTICES],
            tail: [-1; MAX_VERTICES],
            to: [0; MAX_ARCS],
            next: [-1; MAX_ARCS],
            arc_edge: [0; MAX_ARCS],
            edge_u: [0; MAX_EDGES],
            edge_used: [false; MAX_EDGES],
            direction: [0; MAX_EDGES],
            discovery: [-1; MAX_VERTICES],
            low: [0; MAX_VERTICES],
            timer: 0,
            bridges: 0,
        }
    }

    fn append_arc(&mut self, from: usize, target: usize, edge: usize, arc_count: &mut usize) {
        let arc = *arc_count;
        *arc_count += 1;
        self.to[arc] = target as i32;
        self.arc_edge[arc] = edge as i32;
        if self.head[from] == -1 { self.head[from] = arc as i32; }
        else { self.next[self.tail[from] as usize] = arc as i32; }
        self.tail[from] = arc as i32;
    }

    fn visit(&mut self, vertex: usize) {
        self.discovery[vertex] = self.timer;
        self.low[vertex] = self.timer;
        self.timer += 1;
        let mut arc = self.head[vertex];
        while arc != -1 {
            let arc_index = arc as usize;
            let next_arc = self.next[arc_index];
            let edge = self.arc_edge[arc_index] as usize;
            if !self.edge_used[edge] {
                self.edge_used[edge] = true;
                self.direction[edge] = if vertex as i32 == self.edge_u[edge] { 1 } else { -1 };
                let neighbor = self.to[arc_index] as usize;
                if self.discovery[neighbor] == -1 {
                    self.visit(neighbor);
                    if self.low[neighbor] < self.low[vertex] { self.low[vertex] = self.low[neighbor]; }
                    if self.low[neighbor] > self.discovery[vertex] { self.bridges += 1; }
                } else if self.discovery[neighbor] < self.low[vertex] {
                    self.low[vertex] = self.discovery[neighbor];
                }
            }
            arc = next_arc;
        }
    }
}

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    unsafe { std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(offset), 8); }
}

#[no_mangle]
pub unsafe extern "C" fn strong_orientation(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let raw_vertices = *input;
    let raw_edges = *input.add(1);
    if !(1..=MAX_VERTICES as i64).contains(&raw_vertices) || !(0..=MAX_EDGES as i64).contains(&raw_edges) {
        return -1;
    }
    let vertex_count = raw_vertices as usize;
    let edge_count = raw_edges as usize;
    if length != 2 + 2 * edge_count { return -1; }
    for edge in 0..edge_count {
        let left = *input.add(2 + 2 * edge);
        let right = *input.add(3 + 2 * edge);
        if left < 0 || right < 0 || left >= vertex_count as i64 || right >= vertex_count as i64 {
            return -1;
        }
    }
    let output_bytes = 8 * (edge_count + 1);
    if output.is_null() || output_capacity < output_bytes { return -2; }

    let mut graph = Graph::new();
    let mut arc_count = 0usize;
    for edge in 0..edge_count {
        let left = *input.add(2 + 2 * edge) as usize;
        let right = *input.add(3 + 2 * edge) as usize;
        graph.edge_u[edge] = left as i32;
        graph.append_arc(left, right, edge, &mut arc_count);
        graph.append_arc(right, left, edge, &mut arc_count);
    }
    let mut components = 0i32;
    for vertex in 0..vertex_count {
        if graph.discovery[vertex] == -1 {
            components += 1;
            graph.visit(vertex);
        }
    }
    store_i64_le(output, 0, (components + graph.bridges) as i64);
    for edge in 0..edge_count { store_i64_le(output, 8 * (edge + 1), graph.direction[edge] as i64); }
    output_bytes as i64
}
