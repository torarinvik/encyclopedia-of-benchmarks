const MAX_N: usize = 16;
const MAX_Q: usize = 32;
const MAX_TOKENS: usize = MAX_N + 2 * (MAX_N - 1 + MAX_Q);
const MAX_INPUT: usize = 3 * MAX_N + 5 * MAX_Q + 1;
const MAX_DELTA: i64 = 1_000;

#[derive(Clone, Copy)]
struct Node {
    left: i32,
    right: i32,
    parent: i32,
    priority: u32,
    sequence_size: usize,
    marker_count: usize,
    marker: bool,
    own_value: i64,
    sum: i64,
    lazy_add: i64,
}

impl Node {
    const EMPTY: Self = Self {
        left: -1, right: -1, parent: -1, priority: 0,
        sequence_size: 0, marker_count: 0, marker: false,
        own_value: 0, sum: 0, lazy_add: 0,
    };
}

struct EulerTour {
    nodes: [Node; MAX_TOKENS],
    next_node: usize,
    random_state: u32,
}

impl EulerTour {
    fn new() -> Self {
        Self { nodes: [Node::EMPTY; MAX_TOKENS], next_node: 0, random_state: 0x9e37_79b9 }
    }
    fn size(&self, id: i32) -> usize {
        if id < 0 { 0 } else { self.nodes[id as usize].sequence_size }
    }
    fn markers(&self, id: i32) -> usize {
        if id < 0 { 0 } else { self.nodes[id as usize].marker_count }
    }
    fn sum(&self, id: i32) -> i64 {
        if id < 0 { 0 } else { self.nodes[id as usize].sum }
    }
    fn pull(&mut self, id: i32) {
        let i = id as usize;
        let node = self.nodes[i];
        self.nodes[i].sequence_size = 1 + self.size(node.left) + self.size(node.right);
        self.nodes[i].marker_count = usize::from(node.marker) + self.markers(node.left) + self.markers(node.right);
        self.nodes[i].sum = node.own_value + self.sum(node.left) + self.sum(node.right);
    }
    fn apply_add(&mut self, id: i32, delta: i64) {
        if id < 0 { return; }
        let i = id as usize;
        if self.nodes[i].marker_count == 0 { return; }
        self.nodes[i].sum += delta * self.nodes[i].marker_count as i64;
        if self.nodes[i].marker { self.nodes[i].own_value += delta; }
        self.nodes[i].lazy_add += delta;
    }
    fn push(&mut self, id: i32) {
        let i = id as usize;
        let delta = self.nodes[i].lazy_add;
        if delta == 0 { return; }
        let left = self.nodes[i].left;
        let right = self.nodes[i].right;
        self.apply_add(left, delta);
        self.apply_add(right, delta);
        self.nodes[i].lazy_add = 0;
    }
    fn next_priority(&mut self) -> u32 {
        let mut x = self.random_state;
        x ^= x << 13;
        x ^= x >> 17;
        x ^= x << 5;
        self.random_state = x;
        x
    }
    fn new_node(&mut self, marker: bool, value: i64) -> i32 {
        if self.next_node >= MAX_TOKENS { return -1; }
        let id = self.next_node;
        self.next_node += 1;
        self.nodes[id] = Node {
            left: -1, right: -1, parent: -1, priority: self.next_priority(),
            sequence_size: 1, marker_count: usize::from(marker), marker,
            own_value: if marker { value } else { 0 },
            sum: if marker { value } else { 0 }, lazy_add: 0,
        };
        id as i32
    }
    fn split(&mut self, root: i32, count: usize) -> (i32, i32) {
        if root < 0 { return (-1, -1); }
        self.push(root);
        let i = root as usize;
        self.nodes[i].parent = -1;
        let left = self.nodes[i].left;
        if self.size(left) >= count {
            let (first, middle) = self.split(left, count);
            self.nodes[i].left = middle;
            if middle >= 0 { self.nodes[middle as usize].parent = root; }
            self.pull(root);
            if first >= 0 { self.nodes[first as usize].parent = -1; }
            self.nodes[i].parent = -1;
            (first, root)
        } else {
            let right = self.nodes[i].right;
            let (middle, second) = self.split(right, count - self.size(left) - 1);
            self.nodes[i].right = middle;
            if middle >= 0 { self.nodes[middle as usize].parent = root; }
            self.pull(root);
            self.nodes[i].parent = -1;
            if second >= 0 { self.nodes[second as usize].parent = -1; }
            (root, second)
        }
    }
    fn merge(&mut self, first: i32, second: i32) -> i32 {
        if first < 0 { if second >= 0 { self.nodes[second as usize].parent = -1; } return second; }
        if second < 0 { self.nodes[first as usize].parent = -1; return first; }
        self.nodes[first as usize].parent = -1;
        self.nodes[second as usize].parent = -1;
        if self.nodes[first as usize].priority >= self.nodes[second as usize].priority {
            self.push(first);
            let right = self.nodes[first as usize].right;
            let joined = self.merge(right, second);
            self.nodes[first as usize].right = joined;
            if joined >= 0 { self.nodes[joined as usize].parent = first; }
            self.pull(first);
            self.nodes[first as usize].parent = -1;
            first
        } else {
            self.push(second);
            let left = self.nodes[second as usize].left;
            let joined = self.merge(first, left);
            self.nodes[second as usize].left = joined;
            if joined >= 0 { self.nodes[joined as usize].parent = second; }
            self.pull(second);
            self.nodes[second as usize].parent = -1;
            second
        }
    }
    fn root_of(&self, mut node: i32) -> i32 {
        while self.nodes[node as usize].parent >= 0 { node = self.nodes[node as usize].parent; }
        node
    }
    fn rank_of(&self, mut node: i32) -> usize {
        let mut rank = self.size(self.nodes[node as usize].left);
        while self.nodes[node as usize].parent >= 0 {
            let parent = self.nodes[node as usize].parent;
            if self.nodes[parent as usize].right == node {
                rank += 1 + self.size(self.nodes[parent as usize].left);
            }
            node = parent;
        }
        rank
    }
    fn rotate_to(&mut self, node: i32) -> i32 {
        let root = self.root_of(node);
        let rank = self.rank_of(node);
        let (first, second) = self.split(root, rank);
        self.merge(second, first)
    }
    fn link(&mut self, markers: &[i32; MAX_N], u: usize, v: usize) -> Option<(i32, i32)> {
        let root_u = self.root_of(markers[u]);
        let root_v = self.root_of(markers[v]);
        if root_u == root_v { return None; }
        let index_u = self.rank_of(markers[u]);
        let index_v = self.rank_of(markers[v]);
        let (a0, a1) = self.split(root_u, index_u + 1);
        let (b0, tail) = self.split(root_v, index_v);
        let (vm, b1) = self.split(tail, 1);
        let uv = self.new_node(false, 0);
        let vu = self.new_node(false, 0);
        if uv < 0 || vu < 0 { return None; }
        let mut root = self.merge(a0, uv);
        root = self.merge(root, b1);
        root = self.merge(root, b0);
        root = self.merge(root, vm);
        root = self.merge(root, vu);
        self.merge(root, a1);
        Some((uv, vu))
    }
    fn cut(&mut self, uv: i32, vu: i32) -> bool {
        let root = self.rotate_to(uv);
        let reverse_rank = self.rank_of(vu);
        if reverse_rank == 0 { return false; }
        let (first, rest) = self.split(root, 1);
        let (_, tail) = self.split(rest, reverse_rank - 1);
        let (reverse, _) = self.split(tail, 1);
        if first != uv || reverse != vu { return false; }
        self.nodes[uv as usize].left = -1;
        self.nodes[uv as usize].right = -1;
        self.nodes[uv as usize].parent = -1;
        self.nodes[vu as usize].left = -1;
        self.nodes[vu as usize].right = -1;
        self.nodes[vu as usize].parent = -1;
        true
    }
    fn side(&mut self, uv: i32, vu: i32, update: Option<i64>) -> Option<i64> {
        let root = self.rotate_to(uv);
        let reverse_rank = self.rank_of(vu);
        if reverse_rank == 0 { return None; }
        let (edge, rest) = self.split(root, 1);
        let (side, tail) = self.split(rest, reverse_rank - 1);
        if edge != uv || side < 0 { return None; }
        let answer = if let Some(delta) = update {
            self.apply_add(side, delta);
            0
        } else { self.sum(side) };
        let joined = self.merge(edge, side);
        self.merge(joined, tail);
        Some(answer)
    }
}

fn connected(adjacency: &[[bool; MAX_N]; MAX_N], n: usize, start: usize, goal: usize) -> bool {
    let mut seen = [false; MAX_N];
    let mut queue = [0usize; MAX_N];
    let (mut head, mut tail) = (0usize, 0usize);
    queue[tail] = start; tail += 1; seen[start] = true;
    while head < tail {
        let u = queue[head]; head += 1;
        if u == goal { return true; }
        for v in 0..n {
            if adjacency[u][v] && !seen[v] { seen[v] = true; queue[tail] = v; tail += 1; }
        }
    }
    false
}
fn validate_fields(input: &[i64], n: usize, q: usize) -> Option<usize> {
    if input[2..2 + n].iter().any(|&x| !(0..=MAX_DELTA).contains(&x)) { return None; }
    let edge_start = 2 + n;
    for i in 0..n - 1 {
        let u = input[edge_start + 2 * i]; let v = input[edge_start + 2 * i + 1];
        if u < 0 || u >= n as i64 || v < 0 || v >= n as i64 || u == v { return None; }
    }
    let operations = edge_start + 2 * (n - 1);
    let mut queries = 0;
    for i in 0..q {
        let at = operations + 5 * i;
        let (kind, v, p, a, b) = (input[at], input[at + 1], input[at + 2], input[at + 3], input[at + 4]);
        if kind == 0 {
            if v < 0 || v >= n as i64 || p < 0 || p >= n as i64 || a < 0 || a >= n as i64 ||
                b < 0 || b >= n as i64 || v == p || a == b { return None; }
        } else if kind == 1 {
            if v < 0 || v >= n as i64 || p < 0 || p >= n as i64 || v == p ||
                !(0..=MAX_DELTA).contains(&a) || b != 0 { return None; }
        } else if kind == 2 {
            if v < 0 || v >= n as i64 || p < 0 || p >= n as i64 || v == p || a != 0 || b != 0 { return None; }
            queries += 1;
        } else { return None; }
    }
    Some(queries)
}
fn validate_topology(input: &[i64], n: usize, q: usize) -> bool {
    let mut adjacency = [[false; MAX_N]; MAX_N];
    let edge_start = 2 + n;
    let operations = edge_start + 2 * (n - 1);
    for i in 0..n - 1 {
        let u = input[edge_start + 2 * i] as usize;
        let v = input[edge_start + 2 * i + 1] as usize;
        if adjacency[u][v] { return false; }
        adjacency[u][v] = true; adjacency[v][u] = true;
    }
    for v in 0..n { if !connected(&adjacency, n, 0, v) { return false; } }
    for i in 0..q {
        let at = operations + 5 * i;
        let kind = input[at] as usize;
        let v = input[at + 1] as usize; let p = input[at + 2] as usize;
        if kind == 0 {
            let a = input[at + 3] as usize; let b = input[at + 4] as usize;
            if !adjacency[v][p] { return false; }
            adjacency[v][p] = false; adjacency[p][v] = false;
            if connected(&adjacency, n, a, b) { return false; }
            adjacency[a][b] = true; adjacency[b][a] = true;
        } else if !adjacency[v][p] { return false; }
    }
    true
}
unsafe fn put_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn dynamic_tree_subtree_add_subtree_sum(
    input: *const i64, input_length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 2 || input_length > MAX_INPUT { return -1; }
    let words = std::slice::from_raw_parts(input, input_length);
    let n64 = words[0]; let q64 = words[1];
    if !(1..=MAX_N as i64).contains(&n64) || !(0..=MAX_Q as i64).contains(&q64) { return -1; }
    let n = n64 as usize; let q = q64 as usize;
    if input_length != 3 * n + 5 * q { return -1; }
    let Some(query_count) = validate_fields(words, n, q) else { return -1; };
    if !validate_topology(words, n, q) { return -1; }
    let output_bytes = query_count * 8;
    if output_bytes > 0 && (output.is_null() || output_capacity < output_bytes) { return -2; }

    let mut tour = EulerTour::new();
    let mut markers = [-1i32; MAX_N];
    for i in 0..n { markers[i] = tour.new_node(true, words[2 + i]); }
    let mut directed = [[-1i32; MAX_N]; MAX_N];
    let edge_start = 2 + n; let operations = edge_start + 2 * (n - 1);
    for i in 0..n - 1 {
        let u = words[edge_start + 2 * i] as usize; let v = words[edge_start + 2 * i + 1] as usize;
        let Some((uv, vu)) = tour.link(&markers, u, v) else { return -1; };
        directed[u][v] = uv; directed[v][u] = vu;
    }
    let mut answers = [0i64; MAX_Q];
    let mut answer_count = 0;
    for i in 0..q {
        let at = operations + 5 * i;
        let kind = words[at] as usize; let v = words[at + 1] as usize; let p = words[at + 2] as usize;
        if kind == 0 {
            let a = words[at + 3] as usize; let b = words[at + 4] as usize;
            let uv = directed[v][p]; let vu = directed[p][v];
            if uv < 0 || vu < 0 || !tour.cut(uv, vu) { return -1; }
            directed[v][p] = -1; directed[p][v] = -1;
            let Some((new_uv, new_vu)) = tour.link(&markers, a, b) else { return -1; };
            directed[a][b] = new_uv; directed[b][a] = new_vu;
        } else if kind == 1 {
            if tour.side(directed[p][v], directed[v][p], Some(words[at + 3])).is_none() { return -1; }
        } else {
            let Some(answer) = tour.side(directed[p][v], directed[v][p], None) else { return -1; };
            answers[answer_count] = answer; answer_count += 1;
        }
    }
    for i in 0..answer_count { put_i64_le(output, i * 8, answers[i]); }
    output_bytes as i64
}
