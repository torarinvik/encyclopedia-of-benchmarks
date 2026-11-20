const ALPHABET: usize = 16;
const MAX_NODES: usize = 31;
const MAX_INPUT: usize = 66;
const MAX_PACKED: usize = 152;
const NYT: i32 = 0;
const LEAF: i32 = 1;
const INTERNAL: i32 = 2;

#[derive(Clone, Copy)]
struct Node { parent: i32, left: i32, right: i32, symbol: i32, kind: i32, weight: i64 }
impl Node { const EMPTY: Self = Self { parent: -1, left: -1, right: -1, symbol: -1, kind: NYT, weight: 0 }; }
#[derive(Clone, Copy)]
struct Ordered { id: usize, depth: usize, path: usize }
impl Ordered { const EMPTY: Self = Self { id: 0, depth: 0, path: 0 }; }
struct Tree {
    nodes: [Node; MAX_NODES], count: usize, root: usize, nyt: i32,
    leaf: [i32; ALPHABET], order: [usize; MAX_NODES], order_count: usize,
    bits: [u8; MAX_PACKED], bit_count: usize,
}
impl Tree {
    fn new() -> Self {
        let mut t = Self { nodes: [Node::EMPTY; MAX_NODES], count: 1, root: 0, nyt: 0,
            leaf: [-1; ALPHABET], order: [0; MAX_NODES], order_count: 1,
            bits: [0; MAX_PACKED], bit_count: 0 };
        t.nodes[0] = Node::EMPTY;
        t
    }
    fn put_bit(&mut self, value: usize) {
        if value != 0 { self.bits[self.bit_count / 8] |= 1 << (7 - self.bit_count % 8); }
        self.bit_count += 1;
    }
    fn put_value(&mut self, value: usize, width: usize) {
        for shift in (0..width).rev() { self.put_bit((value >> shift) & 1); }
    }
    fn encode_path(&mut self, mut node: usize) {
        let mut reverse = [0usize; MAX_NODES]; let mut depth = 0;
        while node != self.root {
            let parent = self.nodes[node].parent as usize;
            reverse[depth] = usize::from(self.nodes[parent].right == node as i32);
            depth += 1; node = parent;
        }
        while depth > 0 { depth -= 1; self.put_bit(reverse[depth]); }
    }
    fn ancestor(&self, ancestor: usize, node: usize) -> bool {
        let mut at = self.nodes[node].parent;
        while at >= 0 { if at as usize == ancestor { return true; } at = self.nodes[at as usize].parent; }
        false
    }
    fn replace_child(&mut self, parent: usize, old: usize, new: usize) {
        if self.nodes[parent].left == old as i32 { self.nodes[parent].left = new as i32; }
        else if self.nodes[parent].right == old as i32 { self.nodes[parent].right = new as i32; }
    }
    fn swap(&mut self, a: usize, b: usize, update_order: bool) {
        if a == b || self.nodes[a].parent == b as i32 || self.nodes[b].parent == a as i32
            || self.ancestor(a, b) || self.ancestor(b, a) { return; }
        let (pa, pb) = (self.nodes[a].parent, self.nodes[b].parent);
        if pa == pb {
            if pa >= 0 { let p = pa as usize; let temp = self.nodes[p].left; self.nodes[p].left = self.nodes[p].right; self.nodes[p].right = temp; }
        } else {
            if pa >= 0 { self.replace_child(pa as usize, a, b); }
            if pb >= 0 { self.replace_child(pb as usize, b, a); }
            self.nodes[a].parent = pb; self.nodes[b].parent = pa;
        }
        if self.root == a { self.root = b; } else if self.root == b { self.root = a; }
        if update_order {
            let mut ra = None; let mut rb = None;
            for i in 0..self.order_count { if self.order[i] == a { ra = Some(i); } if self.order[i] == b { rb = Some(i); } }
            if let (Some(x), Some(y)) = (ra, rb) { self.order[x] = b; self.order[y] = a; }
        }
    }
    fn add_node(&mut self, parent: usize, kind: i32, symbol: i32) -> usize {
        let id = self.count; self.count += 1;
        self.nodes[id] = Node { parent: parent as i32, left: -1, right: -1, symbol, kind, weight: 0 }; id
    }
    fn split(&mut self, symbol: usize, remaining: bool, fgk: bool) -> usize {
        let old = self.nyt as usize;
        if !remaining {
            self.nodes[old].kind = LEAF; self.nodes[old].symbol = symbol as i32;
            self.leaf[symbol] = old as i32; self.nyt = -1; return old;
        }
        let left = self.add_node(old, NYT, -1); let right = self.add_node(old, LEAF, symbol as i32);
        self.nodes[old].kind = INTERNAL; self.nodes[old].left = left as i32; self.nodes[old].right = right as i32;
        self.leaf[symbol] = right as i32; self.nyt = left as i32;
        if fgk {
            let mut pos = 0; while self.order[pos] != old { pos += 1; }
            for i in (pos + 3..=self.order_count + 1).rev() { self.order[i] = self.order[i - 2]; }
            self.order[pos] = left; self.order[pos + 1] = right; self.order[pos + 2] = old;
            self.order_count += 2;
        }
        right
    }
    fn fgk_leader(&self, node: usize, leaves_only: bool) -> usize {
        let parent = self.nodes[node].parent;
        for i in (0..self.order_count).rev() {
            let candidate = self.order[i];
            if candidate as i32 == parent || self.nodes[candidate].weight != self.nodes[node].weight
                || (leaves_only && self.nodes[candidate].kind == INTERNAL)
                || self.ancestor(candidate, node) || self.ancestor(node, candidate) { continue; }
            return candidate;
        }
        node
    }
    fn update_fgk(&mut self, mut node: usize) {
        let parent = self.nodes[node].parent;
        if self.nyt >= 0 && parent >= 0 && self.nodes[self.nyt as usize].parent == parent {
            let leader = self.fgk_leader(node, true); self.swap(node, leader, true);
            self.nodes[node].weight += 1; node = self.nodes[node].parent as usize;
        }
        while node != self.root {
            let leader = self.fgk_leader(node, false); self.swap(node, leader, true);
            self.nodes[node].weight += 1; node = self.nodes[node].parent as usize;
        }
        self.nodes[self.root].weight += 1;
    }
    fn implicit_order(&self, out: &mut [Ordered; MAX_NODES]) -> usize {
        for id in 0..self.count {
            let mut reverse = [0usize; MAX_NODES]; let mut depth = 0; let mut at = id;
            while at != self.root { let p = self.nodes[at].parent as usize; reverse[depth] = usize::from(self.nodes[p].right == at as i32); depth += 1; at = p; }
            let mut path = 0; for i in (0..depth).rev() { path = path * 2 + reverse[i]; }
            out[id] = Ordered { id, depth, path };
        }
        for i in 1..self.count {
            let value = out[i]; let mut j = i;
            while j > 0 && (out[j-1].depth < value.depth || (out[j-1].depth == value.depth && out[j-1].path > value.path)) { out[j] = out[j-1]; j -= 1; }
            out[j] = value;
        }
        self.count
    }
    fn vitter_leader(&self, node: usize, order: &mut [Ordered; MAX_NODES]) -> usize {
        let count = self.implicit_order(order);
        for i in (0..count).rev() { let id = order[i].id; if self.nodes[id].weight == self.nodes[node].weight && self.nodes[id].kind == self.nodes[node].kind { return id; } }
        node
    }
    fn slide_increment(&mut self, node: usize, order: &mut [Ordered; MAX_NODES]) -> usize {
        let old_parent = self.nodes[node].parent;
        let target_kind = if self.nodes[node].kind == LEAF { INTERNAL } else { LEAF };
        let target_weight = self.nodes[node].weight + if self.nodes[node].kind == LEAF { 0 } else { 1 };
        let count = self.implicit_order(order); let mut block = [0usize; MAX_NODES]; let mut used = 0;
        for item in order.iter().take(count) { let id = item.id; if self.nodes[id].kind == target_kind && self.nodes[id].weight == target_weight { block[used] = id; used += 1; } }
        for &id in block.iter().take(used) { if id != node { self.swap(node, id, false); } }
        self.nodes[node].weight += 1;
        if self.nodes[node].kind == LEAF { self.nodes[node].parent as usize } else { old_parent as usize }
    }
    fn update_vitter(&mut self, mut node: usize, just_split: bool) {
        let mut order = [Ordered::EMPTY; MAX_NODES]; let mut leaf_to_increment = None;
        if just_split { leaf_to_increment = Some(node); node = self.nodes[node].parent as usize; }
        else {
            let leader = self.vitter_leader(node, &mut order); self.swap(node, leader, false);
            let parent = self.nodes[node].parent;
            if self.nyt >= 0 && parent >= 0 && self.nodes[self.nyt as usize].parent == parent { leaf_to_increment = Some(node); node = parent as usize; }
        }
        while node != self.root { node = self.slide_increment(node, &mut order); }
        if let Some(leaf) = leaf_to_increment { let _ = self.slide_increment(leaf, &mut order); }
        self.nodes[self.root].weight += 1;
    }
}

fn encode(input: &[i64], vitter: bool) -> Result<([u8; MAX_PACKED], usize), i64> {
    if input.is_empty() || input.len() > MAX_INPUT { return Err(-1); }
    let n = input[0]; if !(0..=64).contains(&n) || input.len() != 1 + n as usize { return Err(-1); }
    if input[1..].iter().any(|&x| !(0..16).contains(&x)) { return Err(-1); }
    let mut tree = Tree::new(); let mut seen = 0;
    for &value in &input[1..] {
        let symbol = value as usize; let is_new = tree.leaf[symbol] < 0;
        let mut current = if is_new { tree.nyt as usize } else { tree.leaf[symbol] as usize };
        tree.encode_path(current);
        if is_new { tree.put_value(symbol, 4); seen += 1; let split = seen < ALPHABET; current = tree.split(symbol, split, !vitter); if vitter { tree.update_vitter(current, split); } else { tree.update_fgk(current); } }
        else if vitter { tree.update_vitter(current, false); } else { tree.update_fgk(current); }
    }
    Ok((tree.bits, tree.bit_count))
}
fn call(input: *const i64, length: usize, output: *mut u8, capacity: usize, vitter: bool) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT { return -1; }
    let result = unsafe { encode(std::slice::from_raw_parts(input, length), vitter) };
    let (bits, count) = match result { Ok(value) => value, Err(code) => return code };
    let packed = (count + 7) / 8; let required = 8 + packed;
    if output.is_null() || capacity < required { return -2; }
    unsafe {
        let count64 = (count as u64).to_le_bytes();
        for i in 0..8 { *output.add(i) = count64[i]; }
        for i in 0..packed { *output.add(8+i) = bits[i]; }
    }
    required as i64
}
#[no_mangle]
pub unsafe extern "C" fn fgk_adaptive_huffman(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 { call(input, length, output, capacity, false) }
#[no_mangle]
pub unsafe extern "C" fn vitter_adaptive_huffman(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 { call(input, length, output, capacity, true) }
