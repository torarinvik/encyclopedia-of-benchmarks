const MAX_VERTICES: usize = 64;
const MAX_EDGES: i64 = 128;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_EDGES as usize + 1;

struct BridgeState {
    dsu_2ecc: [i32; MAX_VERTICES],
    dsu_cc: [i32; MAX_VERTICES],
    dsu_cc_size: [i32; MAX_VERTICES],
    parent: [i32; MAX_VERTICES],
    last_visit: [i32; MAX_VERTICES],
    iteration: i32,
    bridges: i32,
}

impl BridgeState {
    fn new(vertex_count: usize) -> Self {
        let mut state = Self {
            dsu_2ecc: [0; MAX_VERTICES],
            dsu_cc: [0; MAX_VERTICES],
            dsu_cc_size: [0; MAX_VERTICES],
            parent: [-1; MAX_VERTICES],
            last_visit: [0; MAX_VERTICES],
            iteration: 0,
            bridges: 0,
        };
        for vertex in 0..vertex_count {
            state.dsu_2ecc[vertex] = vertex as i32;
            state.dsu_cc[vertex] = vertex as i32;
            state.dsu_cc_size[vertex] = 1;
        }
        state
    }

    fn find_2ecc(&mut self, vertex: i32) -> i32 {
        if vertex == -1 { return -1; }
        let index = vertex as usize;
        if self.dsu_2ecc[index] == vertex { return vertex; }
        let next = self.dsu_2ecc[index];
        let representative = self.find_2ecc(next);
        self.dsu_2ecc[index] = representative;
        representative
    }

    fn find_cc(&mut self, vertex: i32) -> i32 {
        let representative = self.find_2ecc(vertex);
        let index = representative as usize;
        if self.dsu_cc[index] == representative { return representative; }
        let next = self.dsu_cc[index];
        let root = self.find_cc(next);
        self.dsu_cc[index] = root;
        root
    }

    fn make_root(&mut self, vertex: i32) {
        let root = self.find_2ecc(vertex);
        let mut current = root;
        let mut child = -1;
        while current != -1 {
            let index = current as usize;
            let parent = self.parent[index];
            let next = self.find_2ecc(parent);
            self.parent[index] = child;
            self.dsu_cc[index] = root;
            child = current;
            current = next;
        }
        let component_size = self.dsu_cc_size[child as usize];
        self.dsu_cc_size[root as usize] = component_size;
    }

    fn merge_path(&mut self, mut left: i32, mut right: i32) {
        self.iteration += 1;
        let mut path_left = [0i32; MAX_VERTICES];
        let mut path_right = [0i32; MAX_VERTICES];
        let mut left_length = 0usize;
        let mut right_length = 0usize;
        let mut lca = -1;
        while lca == -1 {
            if left != -1 {
                left = self.find_2ecc(left);
                path_left[left_length] = left;
                left_length += 1;
                let index = left as usize;
                if self.last_visit[index] == self.iteration { lca = left; break; }
                self.last_visit[index] = self.iteration;
                left = self.parent[index];
            }
            if right != -1 {
                right = self.find_2ecc(right);
                path_right[right_length] = right;
                right_length += 1;
                let index = right as usize;
                if self.last_visit[index] == self.iteration { lca = right; break; }
                self.last_visit[index] = self.iteration;
                right = self.parent[index];
            }
        }
        for &vertex in &path_left[..left_length] {
            self.dsu_2ecc[vertex as usize] = lca;
            if vertex == lca { break; }
            self.bridges -= 1;
        }
        for &vertex in &path_right[..right_length] {
            self.dsu_2ecc[vertex as usize] = lca;
            if vertex == lca { break; }
            self.bridges -= 1;
        }
    }

    fn add_edge(&mut self, left_input: i32, right_input: i32) {
        let mut left = self.find_2ecc(left_input);
        let mut right = self.find_2ecc(right_input);
        if left == right { return; }
        let mut left_cc = self.find_cc(left);
        let mut right_cc = self.find_cc(right);
        if left_cc != right_cc {
            self.bridges += 1;
            if self.dsu_cc_size[left_cc as usize] > self.dsu_cc_size[right_cc as usize] {
                std::mem::swap(&mut left, &mut right);
                std::mem::swap(&mut left_cc, &mut right_cc);
            }
            self.make_root(left);
            self.parent[left as usize] = right;
            self.dsu_cc[left as usize] = right;
            let left_size = self.dsu_cc_size[left as usize];
            self.dsu_cc_size[right_cc as usize] += left_size;
        } else {
            self.merge_path(left, right);
        }
    }
}

/// Input is `[n, m, edges...]`; output holds bridge counts after each insertion.
#[no_mangle]
pub unsafe extern "C" fn online_bridge_finding(
    values: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if values.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let vertex_count = *values;
    let edge_count = *values.add(1);
    if !(1..=MAX_VERTICES as i64).contains(&vertex_count) || !(0..=MAX_EDGES).contains(&edge_count) {
        return -1;
    }
    let vertex_count = vertex_count as usize;
    let edge_count = edge_count as usize;
    if length != 2 + 2 * edge_count { return -1; }
    for edge in 0..edge_count {
        let left = *values.add(2 + 2 * edge);
        let right = *values.add(3 + 2 * edge);
        if left < 0 || right < 0 || left >= vertex_count as i64 || right >= vertex_count as i64 {
            return -1;
        }
    }
    let output_bytes = edge_count * 8;
    if output_bytes > 0 && (output.is_null() || capacity < output_bytes) { return -2; }

    let mut state = BridgeState::new(vertex_count);
    for edge in 0..edge_count {
        state.add_edge(*values.add(2 + 2 * edge) as i32, *values.add(3 + 2 * edge) as i32);
        let bytes = (state.bridges as i64).to_le_bytes();
        std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(edge * 8), 8);
    }
    output_bytes as i64
}
