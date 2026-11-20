const MAX_N: usize = 64;
const MAX_Q: usize = 64;
const MAX_INPUT: usize = 323;
const TREE_BASE: usize = 128;
const TREE_SIZE: usize = 256;

#[derive(Clone, Copy, Default)]
struct Segment {
    balance: i32,
    prefix_min: i32,
    suffix_max: i32,
    min_insert: i32,
    max_delete: i32,
}

struct RetroQueue {
    types: [i32; MAX_N + 1],
    values: [i64; MAX_N + 1],
    tree: [Segment; TREE_SIZE],
    live_count: i64,
    live_sum: i64,
}

impl RetroQueue {
    fn new() -> Self {
        let mut q = Self {
            types: [2; MAX_N + 1],
            values: [-1; MAX_N + 1],
            tree: [Segment::default(); TREE_SIZE],
            live_count: 0,
            live_sum: 0,
        };
        for node in &mut q.tree { node.max_delete = -1; }
        q
    }

    fn choose_min(&self, a: i32, b: i32) -> i32 {
        if a == 0 { return b; }
        if b == 0 { return a; }
        if self.values[a as usize] != self.values[b as usize] {
            return if self.values[a as usize] < self.values[b as usize] { a } else { b };
        }
        a.max(b)
    }

    fn choose_max(&self, a: i32, b: i32) -> i32 {
        if a == -1 { return b; }
        if b == -1 { return a; }
        if a == 0 || b == 0 { return 0; }
        if self.values[a as usize] != self.values[b as usize] {
            return if self.values[a as usize] > self.values[b as usize] { a } else { b };
        }
        a.min(b)
    }

    fn pull(&mut self, i: usize) {
        let mut p = (TREE_BASE + i) >> 1;
        while p != 0 {
            let left = self.tree[p << 1];
            let right = self.tree[(p << 1) | 1];
            self.tree[p] = Segment {
                balance: left.balance + right.balance,
                prefix_min: left.prefix_min.min(left.balance + right.prefix_min),
                suffix_max: (left.suffix_max + right.balance).max(right.suffix_max),
                min_insert: self.choose_min(left.min_insert, right.min_insert),
                max_delete: self.choose_max(left.max_delete, right.max_delete),
            };
            p >>= 1;
        }
    }

    fn next_bridge(&self, i: usize) -> usize {
        let mut left = TREE_BASE;
        let mut right = TREE_BASE + i + 1;
        let mut acc = 0i32;
        while left < right {
            if left & 1 == 1 { acc += self.tree[left].balance; left += 1; }
            if right & 1 == 1 { right -= 1; acc += self.tree[right].balance; }
            left >>= 1;
            right >>= 1;
        }
        if acc == 0 { return i + 1; }
        let mut node = TREE_BASE + i + 1;
        loop {
            while node & 1 == 0 { node >>= 1; }
            if acc + self.tree[node].prefix_min == 0 {
                while node < TREE_BASE {
                    node <<= 1;
                    if acc + self.tree[node].prefix_min > 0 {
                        acc += self.tree[node].balance;
                        node += 1;
                    }
                }
                return node - TREE_BASE;
            }
            acc += self.tree[node].balance;
            node += 1;
            if (node & node.wrapping_neg()) == node { return TREE_BASE; }
        }
    }

    fn prev_bridge(&self, i: usize) -> usize {
        let mut left = TREE_BASE + i;
        let mut right = TREE_BASE * 2;
        let mut acc = 0i32;
        while left < right {
            if left & 1 == 1 { acc += self.tree[left].balance; left += 1; }
            if right & 1 == 1 { right -= 1; acc += self.tree[right].balance; }
            left >>= 1;
            right >>= 1;
        }
        if acc == 0 { return i; }
        let mut node = TREE_BASE + i;
        loop {
            node -= 1;
            while node > 1 && node & 1 == 1 { node >>= 1; }
            if self.tree[node].suffix_max + acc == 0 {
                while node < TREE_BASE {
                    node = (node << 1) | 1;
                    if self.tree[node].suffix_max + acc < 0 {
                        acc += self.tree[node].balance;
                        node -= 1;
                    }
                }
                return node - TREE_BASE;
            }
            acc += self.tree[node].balance;
            if (node & node.wrapping_neg()) == node { return 0; }
        }
    }

    fn minimum_insert(&self, i: usize) -> i32 {
        let mut left = TREE_BASE;
        let mut right = TREE_BASE + self.next_bridge(i);
        let mut answer = 0;
        while left < right {
            if left & 1 == 1 { answer = self.choose_min(answer, self.tree[left].min_insert); left += 1; }
            if right & 1 == 1 { right -= 1; answer = self.choose_min(answer, self.tree[right].min_insert); }
            left >>= 1;
            right >>= 1;
        }
        answer
    }

    fn maximum_delete(&self, i: usize) -> i32 {
        let mut left = TREE_BASE + self.prev_bridge(i);
        let mut right = TREE_BASE * 2;
        let mut answer = -1;
        while left < right {
            if left & 1 == 1 { answer = self.choose_max(answer, self.tree[left].max_delete); left += 1; }
            if right & 1 == 1 { right -= 1; answer = self.choose_max(answer, self.tree[right].max_delete); }
            left >>= 1;
            right >>= 1;
        }
        answer
    }

    fn add(&mut self, i: usize) {
        let k = self.maximum_delete(i);
        let leaf_index = TREE_BASE + i;
        if self.choose_max(i as i32, k) == i as i32 {
            self.live_sum += self.values[i];
            self.live_count += 1;
            self.tree[leaf_index].min_insert = i as i32;
            self.pull(i);
            return;
        }
        self.tree[leaf_index].max_delete = i as i32;
        self.tree[leaf_index].balance = 1;
        self.tree[leaf_index].suffix_max = 1;
        self.pull(i);
        let mate = TREE_BASE + k as usize;
        if k == 0 {
            self.tree[mate].balance -= 1;
            self.tree[mate].suffix_max -= 1;
            if self.tree[mate].balance == 0 { self.tree[mate].max_delete = -1; }
        } else {
            self.live_sum += self.values[k as usize];
            self.live_count += 1;
            self.tree[mate].min_insert = k;
            self.tree[mate].max_delete = -1;
            self.tree[mate].balance = 0;
            self.tree[mate].suffix_max = 0;
        }
        self.pull(k as usize);
    }

    fn unadd(&mut self, i: usize) {
        let leaf = TREE_BASE + i;
        if self.tree[leaf].balance == 0 {
            self.live_sum -= self.values[i];
            self.live_count -= 1;
            self.tree[leaf].min_insert = 0;
            self.pull(i);
            return;
        }
        let k = self.minimum_insert(i);
        self.tree[leaf].max_delete = -1;
        self.tree[leaf].balance = 0;
        self.tree[leaf].suffix_max = 0;
        self.pull(i);
        let mate = TREE_BASE + k as usize;
        if k > 0 {
            self.live_sum -= self.values[k as usize];
            self.live_count -= 1;
        }
        self.tree[mate].min_insert = 0;
        self.tree[mate].max_delete = k;
        self.tree[mate].balance += 1;
        self.tree[mate].suffix_max += 1;
        self.pull(k as usize);
    }

    fn pop_min(&mut self, i: usize) {
        let k = self.minimum_insert(i);
        let leaf = TREE_BASE + i;
        self.tree[leaf].balance = -1;
        self.tree[leaf].prefix_min = -1;
        self.pull(i);
        if k > 0 {
            self.live_sum -= self.values[k as usize];
            self.live_count -= 1;
        }
        let mate = TREE_BASE + k as usize;
        self.tree[mate].min_insert = 0;
        self.tree[mate].max_delete = k;
        self.tree[mate].balance += 1;
        self.tree[mate].suffix_max += 1;
        self.pull(k as usize);
    }

    fn unpop_min(&mut self, i: usize) {
        let k = self.maximum_delete(i);
        let leaf = TREE_BASE + i;
        let mate = TREE_BASE + k as usize;
        self.tree[leaf].balance = 0;
        self.tree[leaf].prefix_min = 0;
        self.pull(i);
        if k == 0 {
            self.tree[mate].balance -= 1;
            self.tree[mate].suffix_max -= 1;
            if self.tree[mate].balance == 0 { self.tree[mate].max_delete = -1; }
        } else {
            self.live_sum += self.values[k as usize];
            self.live_count += 1;
            self.tree[mate].min_insert = k;
            self.tree[mate].max_delete = -1;
            self.tree[mate].balance = 0;
            self.tree[mate].suffix_max = 0;
        }
        self.pull(k as usize);
    }

    fn set(&mut self, index: usize, kind: i32, value: i64) {
        let i = index + 1;
        if self.types[i] == 0 { self.unadd(i); }
        else if self.types[i] == 1 { self.unpop_min(i); }
        self.types[i] = kind;
        self.values[i] = value;
        if kind == 0 { self.add(i); }
        else if kind == 1 { self.pop_min(i); }
    }
}

fn validate(input: &[i64]) -> Option<(usize, usize)> {
    if input.len() < 2 || input.len() > MAX_INPUT { return None; }
    if input[0] < 1 || input[0] > MAX_N as i64 || input[1] < 1 || input[1] > MAX_Q as i64 { return None; }
    let n = input[0] as usize;
    let q = input[1] as usize;
    if input.len() != 2 + 2 * n + 3 * q { return None; }
    let mut at = 2;
    for _ in 0..n {
        let kind = input[at];
        let value = input[at + 1];
        at += 2;
        if kind == 0 {
            if !(0..=1_000_000).contains(&value) { return None; }
        } else if (kind == 1 || kind == 2) && value == -1 {
        } else { return None; }
    }
    for _ in 0..q {
        let index = input[at];
        let kind = input[at + 1];
        let value = input[at + 2];
        at += 3;
        if index < 0 || index >= n as i64 { return None; }
        if kind == 0 {
            if !(0..=1_000_000).contains(&value) { return None; }
        } else if (kind == 1 || kind == 2) && value == -1 {
        } else { return None; }
    }
    Some((n, q))
}

#[no_mangle]
pub unsafe extern "C" fn partially_retroactive_priority_queue(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || input_length > MAX_INPUT { return -1; }
    let packed = std::slice::from_raw_parts(input, input_length);
    let Some((n, qn)) = validate(packed) else { return -1; };
    let output_size = 16 * qn;
    if output.is_null() || capacity < output_size { return -2; }
    let mut queue = RetroQueue::new();
    let mut at = 2;
    for i in 0..n {
        let kind = packed[at] as i32;
        let value = packed[at + 1];
        at += 2;
        queue.set(i, kind, value);
    }
    let out = std::slice::from_raw_parts_mut(output, output_size);
    for query in 0..qn {
        let index = packed[at] as usize;
        let kind = packed[at + 1] as i32;
        let value = packed[at + 2];
        at += 3;
        queue.set(index, kind, value);
        let start = query * 16;
        out[start..start + 8].copy_from_slice(&queue.live_count.to_le_bytes());
        out[start + 8..start + 16].copy_from_slice(&queue.live_sum.to_le_bytes());
    }
    output_size as i64
}
