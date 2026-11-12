/// Classical DFS low-link decomposition into vertex-biconnected blocks.
const MAX_N: usize = 6;
const MAX_M: usize = 10;
const MAX_ADJ: usize = 20;
const MAX_BLOCKS: usize = MAX_N + MAX_M;
const MAX_OUTPUT_VALUES: usize = 113;
const MAX_OUTPUT_BYTES: usize = 904;
const MAX_INPUT_LENGTH: usize = 22;

struct Context {
    n: usize,
    m: usize,
    edges: [(usize, usize); MAX_M],
    degree: [usize; MAX_N],
    adjacent_vertex: [[usize; MAX_ADJ]; MAX_N],
    adjacent_edge: [[usize; MAX_ADJ]; MAX_N],
    discovery: [i32; MAX_N],
    low: [i32; MAX_N],
    edge_stack: [usize; MAX_M],
    stack_size: usize,
    clock: usize,
    block_vertices: [[usize; MAX_N]; MAX_BLOCKS],
    block_size: [usize; MAX_BLOCKS],
    block_count: usize,
}

impl Context {
    fn new(n: usize, m: usize) -> Self {
        Self {
            n, m,
            edges: [(0, 0); MAX_M],
            degree: [0; MAX_N],
            adjacent_vertex: [[0; MAX_ADJ]; MAX_N],
            adjacent_edge: [[0; MAX_ADJ]; MAX_N],
            discovery: [-1; MAX_N],
            low: [0; MAX_N],
            edge_stack: [0; MAX_M],
            stack_size: 0,
            clock: 0,
            block_vertices: [[0; MAX_N]; MAX_BLOCKS],
            block_size: [0; MAX_BLOCKS],
            block_count: 0,
        }
    }

    fn append_block(&mut self, stop_edge: usize) {
        let mut member = [false; MAX_N];
        while self.stack_size != 0 {
            self.stack_size -= 1;
            let edge = self.edge_stack[self.stack_size];
            let (left, right) = self.edges[edge];
            member[left] = true;
            member[right] = true;
            if edge == stop_edge { break; }
        }
        let block = self.block_count;
        self.block_count += 1;
        for vertex in 0..self.n {
            if member[vertex] {
                self.block_vertices[block][self.block_size[block]] = vertex;
                self.block_size[block] += 1;
            }
        }
    }

    fn visit(&mut self, vertex: usize, parent_edge: usize) {
        self.discovery[vertex] = self.clock as i32;
        self.low[vertex] = self.clock as i32;
        self.clock += 1;
        for slot in 0..self.degree[vertex] {
            let neighbor = self.adjacent_vertex[vertex][slot];
            let edge = self.adjacent_edge[vertex][slot];
            if edge == parent_edge { continue; }
            if self.discovery[neighbor] < 0 {
                self.edge_stack[self.stack_size] = edge;
                self.stack_size += 1;
                self.visit(neighbor, edge);
                self.low[vertex] = self.low[vertex].min(self.low[neighbor]);
                if self.low[neighbor] >= self.discovery[vertex] { self.append_block(edge); }
            } else if self.discovery[neighbor] < self.discovery[vertex] {
                self.edge_stack[self.stack_size] = edge;
                self.stack_size += 1;
                self.low[vertex] = self.low[vertex].min(self.discovery[neighbor]);
            }
        }
    }

    fn block_less(&self, left: usize, right: usize) -> bool {
        let common = self.block_size[left].min(self.block_size[right]);
        for i in 0..common {
            if self.block_vertices[left][i] != self.block_vertices[right][i] {
                return self.block_vertices[left][i] < self.block_vertices[right][i];
            }
        }
        self.block_size[left] < self.block_size[right]
    }
}

fn store_u64_le(output: &mut [u8; MAX_OUTPUT_BYTES], offset: usize, value: u64) {
    for byte in 0..8 { output[offset + byte] = ((value >> (byte * 8)) & 0xff) as u8; }
}

/// Packed input `[N, M, (u, v)*M]`; writes canonical sorted vertex blocks as LE u64s.
#[no_mangle]
pub unsafe extern "C" fn biconnected_components(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(1..=MAX_N as i64).contains(&values[0]) || !(0..=MAX_M as i64).contains(&values[1]) { return -1; }
    let n = values[0] as usize;
    let m = values[1] as usize;
    if length != 2 + 2 * m { return -1; }

    let mut context = Context::new(n, m);
    for edge in 0..m {
        let left_value = values[2 + 2 * edge];
        let right_value = values[3 + 2 * edge];
        if left_value < 0 || left_value >= n as i64 || right_value < 0 ||
            right_value >= n as i64 || left_value == right_value { return -1; }
        let (left, right) = (left_value as usize, right_value as usize);
        context.edges[edge] = (left, right);
        let left_slot = context.degree[left];
        let right_slot = context.degree[right];
        context.degree[left] += 1;
        context.degree[right] += 1;
        context.adjacent_vertex[left][left_slot] = right;
        context.adjacent_edge[left][left_slot] = edge;
        context.adjacent_vertex[right][right_slot] = left;
        context.adjacent_edge[right][right_slot] = edge;
    }
    for root in 0..n {
        if context.discovery[root] >= 0 { continue; }
        context.visit(root, MAX_M);
        if context.degree[root] == 0 {
            let block = context.block_count;
            context.block_count += 1;
            context.block_vertices[block][0] = root;
            context.block_size[block] = 1;
        }
    }

    let mut order = [0usize; MAX_BLOCKS];
    for i in 0..context.block_count {
        let mut position = i;
        order[i] = i;
        while position > 0 && context.block_less(order[position], order[position - 1]) {
            order.swap(position, position - 1);
            position -= 1;
        }
    }
    let mut staged = [0u8; MAX_OUTPUT_BYTES];
    let mut packed_count = 0usize;
    store_u64_le(&mut staged, packed_count * 8, context.block_count as u64);
    packed_count += 1;
    for i in 0..context.block_count {
        let block = order[i];
        store_u64_le(&mut staged, packed_count * 8, context.block_size[block] as u64);
        packed_count += 1;
        for j in 0..context.block_size[block] {
            store_u64_le(&mut staged, packed_count * 8, context.block_vertices[block][j] as u64);
            packed_count += 1;
        }
    }
    let bytes = 8 * packed_count;
    if output.is_null() || capacity < bytes { return -2; }
    std::slice::from_raw_parts_mut(output, bytes).copy_from_slice(&staged[..bytes]);
    bytes as i64
}
