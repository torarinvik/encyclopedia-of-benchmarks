use std::slice;

const N: usize = 8;
const M: usize = 32;
const NODES: usize = N + 2 * M;
const INPUT_MAX: usize = 2 + N + 3 * M;

#[derive(Clone, Copy, Default)]
struct Op { kind: i64, a: i64, b: i64 }

struct Tree {
    left: [i32; NODES], right: [i32; NODES], parent: [i32; NODES], vertex: [i32; NODES],
    size: [i32; NODES], count: [i32; NODES], value: [i64; NODES], sum: [i64; NODES],
    priority: [u64; NODES], edge_u: [i32; M], edge_v: [i32; M], arc_uv: [i32; M], arc_vu: [i32; M],
    active: [bool; M], next_node: usize, edge_count: usize,
}

impl Tree {
    fn new(weights: &[i64; N], n: usize) -> Self {
        let mut tree = Self {
            left: [-1; NODES], right: [-1; NODES], parent: [-1; NODES], vertex: [-1; NODES],
            size: [0; NODES], count: [0; NODES], value: [0; NODES], sum: [0; NODES],
            priority: [0; NODES], edge_u: [0; M], edge_v: [0; M], arc_uv: [0; M], arc_vu: [0; M],
            active: [false; M], next_node: n, edge_count: 0,
        };
        for i in 0..NODES { tree.priority[i] = mix(i as u64); }
        for i in 0..n { tree.vertex[i] = i as i32; tree.value[i] = weights[i]; tree.sum[i] = weights[i]; tree.size[i] = 1; tree.count[i] = 1; }
        tree
    }
    fn size_of(&self, x: i32) -> i32 { if x < 0 { 0 } else { self.size[x as usize] } }
    fn count_of(&self, x: i32) -> i32 { if x < 0 { 0 } else { self.count[x as usize] } }
    fn sum_of(&self, x: i32) -> i64 { if x < 0 { 0 } else { self.sum[x as usize] } }
    fn pull(&mut self, x: i32) {
        if x < 0 { return; }
        let i = x as usize;
        self.size[i] = 1 + self.size_of(self.left[i]) + self.size_of(self.right[i]);
        let own = if self.vertex[i] >= 0 { 1 } else { 0 };
        self.count[i] = own + self.count_of(self.left[i]) + self.count_of(self.right[i]);
        self.sum[i] = self.value[i] + self.sum_of(self.left[i]) + self.sum_of(self.right[i]);
    }
    fn merge(&mut self, a: i32, b: i32) -> i32 {
        if a < 0 { if b >= 0 { self.parent[b as usize] = -1; } return b; }
        if b < 0 { self.parent[a as usize] = -1; return a; }
        let (ai, bi) = (a as usize, b as usize);
        if self.priority[ai] > self.priority[bi] {
            let child = self.merge(self.right[ai], b); self.right[ai] = child;
            if child >= 0 { self.parent[child as usize] = a; }
            self.pull(a); self.parent[ai] = -1; a
        } else {
            let child = self.merge(a, self.left[bi]); self.left[bi] = child;
            if child >= 0 { self.parent[child as usize] = b; }
            self.pull(b); self.parent[bi] = -1; b
        }
    }
    fn split(&mut self, root: i32, prefix: i32) -> (i32, i32) {
        if root < 0 { return (-1, -1); }
        let i = root as usize;
        if prefix <= self.size_of(self.left[i]) {
            let (first, rest) = self.split(self.left[i], prefix);
            self.left[i] = rest; if rest >= 0 { self.parent[rest as usize] = root; }
            self.pull(root); self.parent[i] = -1; if first >= 0 { self.parent[first as usize] = -1; }
            (first, root)
        } else {
            let left_size = self.size_of(self.left[i]);
            let (first, rest) = self.split(self.right[i], prefix - left_size - 1);
            self.right[i] = first; if first >= 0 { self.parent[first as usize] = root; }
            self.pull(root); self.parent[i] = -1; if rest >= 0 { self.parent[rest as usize] = -1; }
            (root, rest)
        }
    }
    fn root(&self, mut x: i32) -> i32 { while self.parent[x as usize] >= 0 { x = self.parent[x as usize]; } x }
    fn position(&self, mut x: i32) -> i32 {
        let mut result = self.size_of(self.left[x as usize]);
        while self.parent[x as usize] >= 0 {
            let p = self.parent[x as usize]; let pi = p as usize;
            if self.right[pi] == x { result += 1 + self.size_of(self.left[pi]); }
            x = p;
        }
        result
    }
    fn rotate(&mut self, root: i32, x: i32) -> i32 {
        let (first, rest) = self.split(root, self.position(x)); self.merge(rest, first)
    }
    fn link(&mut self, u: usize, v: usize) {
        let a = self.rotate(self.root(u as i32), u as i32);
        let b = self.rotate(self.root(v as i32), v as i32);
        let uv = self.next_node as i32; let vu = uv + 1; self.next_node += 2;
        for x in [uv, vu] { let i = x as usize; self.left[i] = -1; self.right[i] = -1; self.parent[i] = -1; self.vertex[i] = -1; self.value[i] = 0; self.sum[i] = 0; self.size[i] = 1; self.count[i] = 0; }
        let root = self.merge(self.merge(self.merge(a, uv), b), vu); self.parent[root as usize] = -1;
        let e = self.edge_count; self.edge_count += 1; self.edge_u[e] = u as i32; self.edge_v[e] = v as i32;
        self.arc_uv[e] = uv; self.arc_vu[e] = vu; self.active[e] = true;
    }
    fn cut(&mut self, u: usize, v: usize) {
        let edge = (0..self.edge_count).rev().find(|&i| self.active[i] &&
            ((self.edge_u[i] == u as i32 && self.edge_v[i] == v as i32) || (self.edge_u[i] == v as i32 && self.edge_v[i] == u as i32))).unwrap();
        let first_arc = if self.edge_u[edge] == u as i32 && self.edge_v[edge] == v as i32 { self.arc_uv[edge] } else { self.arc_vu[edge] };
        let second_arc = if first_arc == self.arc_uv[edge] { self.arc_vu[edge] } else { self.arc_uv[edge] };
        let root = self.rotate(self.root(first_arc), first_arc);
        let (_, rest) = self.split(root, 1);
        let (between, suffix) = self.split(rest, self.position(second_arc));
        let (_, other) = self.split(suffix, 1);
        if between >= 0 { self.parent[between as usize] = -1; }
        if other >= 0 { self.parent[other as usize] = -1; }
        self.active[edge] = false;
    }
    fn set_weight(&mut self, vertex: usize, value: i64) {
        self.value[vertex] = value;
        let mut path = [0i32; NODES]; let mut count = 0usize; let mut x = vertex as i32;
        while x >= 0 { path[count] = x; count += 1; x = self.parent[x as usize]; }
        for i in 0..count { self.pull(path[i]); }
    }
}

fn mix(mut x: u64) -> u64 {
    x = x.wrapping_add(0x9e3779b97f4a7c15); x = (x ^ (x >> 30)).wrapping_mul(0xbf58476d1ce4e5b9);
    x = (x ^ (x >> 27)).wrapping_mul(0x94d049bb133111eb); x ^ (x >> 31)
}
fn connected(adj: &[[bool; N]; N], start: usize, target: usize, n: usize) -> bool {
    let mut seen = [false; N]; let mut stack = [0usize; N]; let mut top = 0;
    stack[top] = start; top += 1; seen[start] = true;
    while top > 0 { top -= 1; let u = stack[top]; if u == target { return true; }
        for v in 0..n { if adj[u][v] && !seen[v] { seen[v] = true; stack[top] = v; top += 1; } }
    }
    false
}
fn store(output: *mut u8, at: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { unsafe { output.add(at + byte).write((bits >> (8 * byte)) as u8); } }
}

#[no_mangle]
pub unsafe extern "C" fn euler_tour_tree(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > INPUT_MAX { return -1; }
    let words = slice::from_raw_parts(input, length);
    let (nr, mr) = (words[0], words[1]);
    if nr < 1 || nr > N as i64 || mr < 1 || mr > M as i64 { return -1; }
    let (n, m) = (nr as usize, mr as usize); let mut cursor = 2;
    let mut weights = [0i64; N];
    for w in weights.iter_mut().take(n) { if cursor >= length { return -1; } *w = words[cursor]; cursor += 1; if !(-100..=100).contains(w) { return -1; } }
    let mut operations = [Op::default(); M]; let mut query_count = 0usize;
    for op in operations.iter_mut().take(m) {
        if cursor >= length { return -1; } let kind = words[cursor]; cursor += 1;
        if kind == 0 || kind == 1 {
            if cursor + 2 > length { return -1; } let (u, v) = (words[cursor], words[cursor + 1]); cursor += 2;
            if u < 0 || u >= nr || v < 0 || v >= nr || u == v { return -1; } *op = Op { kind, a: u, b: v };
        } else if kind == 2 {
            if cursor + 2 > length { return -1; } let (v, value) = (words[cursor], words[cursor + 1]); cursor += 2;
            if v < 0 || v >= nr || !(-100..=100).contains(&value) { return -1; } *op = Op { kind, a: v, b: value };
        } else if kind == 3 {
            if cursor >= length { return -1; } let v = words[cursor]; cursor += 1;
            if v < 0 || v >= nr { return -1; } *op = Op { kind, a: v, b: 0 }; query_count += 1;
        } else { return -1; }
    }
    if cursor != length || query_count == 0 { return -1; }
    let mut adjacency = [[false; N]; N];
    for op in operations.iter().take(m).copied() {
        let (u, v) = (op.a as usize, op.b as usize);
        if op.kind == 0 { if connected(&adjacency, u, v, n) { return -1; } adjacency[u][v] = true; adjacency[v][u] = true; }
        else if op.kind == 1 { if !adjacency[u][v] { return -1; } adjacency[u][v] = false; adjacency[v][u] = false; }
    }
    let required = 16 * query_count; if output.is_null() || capacity < required { return -2; }
    let mut tree = Tree::new(&weights, n); let mut answers = [0i64; 2 * M]; let mut count = 0usize;
    for op in operations.iter().take(m).copied() {
        let (a, b) = (op.a as usize, op.b);
        if op.kind == 0 { tree.link(a, b as usize); }
        else if op.kind == 1 { tree.cut(a, b as usize); }
        else if op.kind == 2 { tree.set_weight(a, b); }
        else { let root = tree.root(a as i32) as usize; answers[count] = tree.count[root] as i64; answers[count + 1] = tree.sum[root]; count += 2; }
    }
    for i in 0..count { store(output, 8 * i, answers[i]); }
    required as i64
}
