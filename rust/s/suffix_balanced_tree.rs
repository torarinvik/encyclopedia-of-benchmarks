const MAX_TEXT: usize = 32;
const MAX_INPUT: usize = 33;
const TAG_LIMIT: u64 = 1u64 << 62;

struct SuffixTree {
    text: [i64; MAX_TEXT],
    left: [i32; MAX_TEXT],
    right: [i32; MAX_TEXT],
    size: [usize; MAX_TEXT],
    tag: [u64; MAX_TEXT],
    buffer: [usize; MAX_TEXT],
    buffered: usize,
}
impl SuffixTree {
    fn less(&self, x: usize, y: usize, n: usize) -> bool {
        if self.text[x] != self.text[y] { return self.text[x] < self.text[y]; }
        let next_x = if x + 1 < n { self.tag[x + 1] } else { 0 };
        let next_y = if y + 1 < n { self.tag[y + 1] } else { 0 };
        next_x < next_y
    }
    fn node_size(&self, node: i32) -> usize { if node < 0 { 0 } else { self.size[node as usize] } }
    fn flatten(&mut self, root: i32) {
        if root < 0 { return; }
        let node = root as usize;
        let left = self.left[node]; let right = self.right[node];
        self.flatten(left);
        self.buffer[self.buffered] = node; self.buffered += 1;
        self.flatten(right);
    }
    fn build_balanced(&mut self, lo: usize, hi: usize, low: u64, high: u64) -> i32 {
        if lo >= hi { return -1; }
        let mid = lo + (hi - lo) / 2;
        let root = self.buffer[mid];
        let tag = low + (high - low) / 2;
        self.tag[root] = tag;
        let left = self.build_balanced(lo, mid, low, tag);
        let right = self.build_balanced(mid + 1, hi, tag, high);
        self.left[root] = left; self.right[root] = right;
        self.size[root] = 1 + self.node_size(left) + self.node_size(right);
        root as i32
    }
    fn rebuild(&mut self, root: i32, low: u64, high: u64) -> i32 {
        self.buffered = 0; self.flatten(root);
        let count = self.buffered;
        self.build_balanced(0, count, low, high)
    }
    fn insert(&mut self, root: i32, pos: usize, n: usize, low: u64, high: u64) -> i32 {
        if root < 0 {
            self.left[pos] = -1; self.right[pos] = -1; self.size[pos] = 1;
            self.tag[pos] = low + (high - low) / 2;
            return pos as i32;
        }
        let node = root as usize;
        let middle_tag = self.tag[node];
        if self.less(pos, node, n) {
            let child = self.left[node];
            let inserted = self.insert(child, pos, n, low, middle_tag);
            self.left[node] = inserted;
        } else {
            let child = self.right[node];
            let inserted = self.insert(child, pos, n, middle_tag, high);
            self.right[node] = inserted;
        }
        let left_size = self.node_size(self.left[node]);
        let right_size = self.node_size(self.right[node]);
        self.size[node] = 1 + left_size + right_size;
        if 4 * left_size.max(right_size) >= 3 * self.size[node] { self.rebuild(root, low, high) } else { root }
    }
    fn inorder(&self, root: i32, answer: &mut [i64; MAX_TEXT], count: &mut usize) {
        if root < 0 { return; }
        let node = root as usize;
        self.inorder(self.left[node], answer, count);
        answer[*count] = node as i64; *count += 1;
        self.inorder(self.right[node], answer, count);
    }
}
unsafe fn store_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { unsafe { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; } }
}

#[no_mangle]
pub unsafe extern "C" fn suffix_balanced_tree(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let nv = values[0];
    if nv < 0 || nv > MAX_TEXT as i64 || length != 1 + nv as usize { return -1; }
    let n = nv as usize;
    if values[1..].iter().any(|&code| !(0..=255).contains(&code)) { return -1; }
    let required = 8 * n;
    if output.is_null() || capacity < required { return -2; }
    let mut tree = SuffixTree { text: [0; MAX_TEXT], left: [-1; MAX_TEXT], right: [-1; MAX_TEXT],
        size: [0; MAX_TEXT], tag: [0; MAX_TEXT], buffer: [0; MAX_TEXT], buffered: 0 };
    for i in 0..n { tree.text[i] = values[i + 1]; }
    let mut root = -1;
    for pos in (0..n).rev() { root = tree.insert(root, pos, n, 0, TAG_LIMIT); }
    let mut answer = [0i64; MAX_TEXT]; let mut answer_count = 0;
    tree.inorder(root, &mut answer, &mut answer_count);
    for i in 0..answer_count { unsafe { store_le(output, 8 * i, answer[i]); } }
    required as i64
}
