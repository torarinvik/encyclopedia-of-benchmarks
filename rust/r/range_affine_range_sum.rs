const MODULUS: i64 = 998_244_353;
const MAX_LENGTH: usize = 64;
const MAX_OPERATIONS: usize = 64;
const MAX_TREE_NODES: usize = 256;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 387;

struct AffineTree {
    sum: [i64; MAX_TREE_NODES],
    lazy_mul: [i64; MAX_TREE_NODES],
    lazy_add: [i64; MAX_TREE_NODES],
}

impl AffineTree {
    fn new() -> Self {
        Self { sum: [0; MAX_TREE_NODES], lazy_mul: [1; MAX_TREE_NODES],
               lazy_add: [0; MAX_TREE_NODES] }
    }

    fn apply(&mut self, node: usize, length: usize, a: i64, b: i64) {
        self.sum[node] = (a * self.sum[node] + b * length as i64) % MODULUS;
        self.lazy_mul[node] = a * self.lazy_mul[node] % MODULUS;
        self.lazy_add[node] = (a * self.lazy_add[node] + b) % MODULUS;
    }

    fn push(&mut self, node: usize, left: usize, right: usize) {
        if right - left <= 1 || (self.lazy_mul[node] == 1 && self.lazy_add[node] == 0) { return; }
        let middle = left + (right - left) / 2;
        let (a, b) = (self.lazy_mul[node], self.lazy_add[node]);
        self.apply(node * 2, middle - left, a, b);
        self.apply(node * 2 + 1, right - middle, a, b);
        self.lazy_mul[node] = 1;
        self.lazy_add[node] = 0;
    }

    fn build(&mut self, values: &[i64], node: usize, left: usize, right: usize) {
        if right - left == 1 { self.sum[node] = values[left]; return; }
        let middle = left + (right - left) / 2;
        self.build(values, node * 2, left, middle);
        self.build(values, node * 2 + 1, middle, right);
        self.sum[node] = (self.sum[node * 2] + self.sum[node * 2 + 1]) % MODULUS;
    }

    fn update(&mut self, ql: usize, qr: usize, node: usize, left: usize,
              right: usize, a: i64, b: i64) {
        if ql <= left && right <= qr { self.apply(node, right - left, a, b); return; }
        if qr <= left || right <= ql { return; }
        self.push(node, left, right);
        let middle = left + (right - left) / 2;
        self.update(ql, qr, node * 2, left, middle, a, b);
        self.update(ql, qr, node * 2 + 1, middle, right, a, b);
        self.sum[node] = (self.sum[node * 2] + self.sum[node * 2 + 1]) % MODULUS;
    }

    fn query(&mut self, ql: usize, qr: usize, node: usize, left: usize, right: usize) -> i64 {
        if ql <= left && right <= qr { return self.sum[node]; }
        if qr <= left || right <= ql { return 0; }
        self.push(node, left, right);
        let middle = left + (right - left) / 2;
        (self.query(ql, qr, node * 2, left, middle) +
         self.query(ql, qr, node * 2 + 1, middle, right)) % MODULUS
    }
}

#[no_mangle]
pub unsafe extern "C" fn range_affine_range_sum_benchmark(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 1 || values[0] > MAX_LENGTH as i64 { return -1; }
    let n = values[0] as usize;
    if length < n + 2 { return -1; }
    let mut initial = [0_i64; MAX_LENGTH];
    for i in 0..n {
        if !(0..MODULUS).contains(&values[i + 1]) { return -1; }
        initial[i] = values[i + 1];
    }
    if values[n + 1] < 1 || values[n + 1] > MAX_OPERATIONS as i64 { return -1; }
    let operation_count = values[n + 1] as usize;
    let mut tree = AffineTree::new();
    tree.build(&initial[..n], 1, 0, n);
    let mut cursor = n + 2;
    let mut checksum = 0_i64;
    for operation in 0..operation_count {
        if cursor >= length { return -1; }
        let opcode = values[cursor];
        cursor += 1;
        if opcode == 0 {
            if cursor + 4 > length { return -1; }
            let (left, right, a, b) = (values[cursor], values[cursor + 1], values[cursor + 2], values[cursor + 3]);
            cursor += 4;
            if left < 0 || left >= right || right > n as i64 ||
               !(1..MODULUS).contains(&a) || !(0..MODULUS).contains(&b) { return -1; }
            tree.update(left as usize, right as usize, 1, 0, n, a, b);
        } else if opcode == 1 {
            if cursor + 2 > length { return -1; }
            let (left, right) = (values[cursor], values[cursor + 1]);
            cursor += 2;
            if left < 0 || left >= right || right > n as i64 { return -1; }
            let result = tree.query(left as usize, right as usize, 1, 0, n);
            checksum += (operation as i64 + 1) * (result + MODULUS);
        } else { return -1; }
    }
    if cursor == length { checksum } else { -1 }
}
