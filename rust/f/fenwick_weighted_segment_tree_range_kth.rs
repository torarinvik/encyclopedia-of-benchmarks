/// Dynamic range k-th via a Fenwick tree of mutable weighted value trees.
const MAX_N: usize = 12;
const MAX_Q: usize = 16;
const VALUE_COUNT: usize = 61;
const NODE_CAPACITY: usize = 1280;

struct Pool {
    left: [usize; NODE_CAPACITY + 1],
    right: [usize; NODE_CAPACITY + 1],
    count: [i32; NODE_CAPACITY + 1],
    roots: [usize; MAX_N + 1],
    used: usize,
}

impl Pool {
    fn change(&mut self, root_arg: usize, low: usize, high: usize,
              coordinate: usize, delta: i32) -> usize {
        let mut root = root_arg;
        if root == 0 {
            self.used += 1;
            root = self.used;
        }
        self.count[root] += delta;
        if high - low > 1 {
            let middle = (low + high) / 2;
            if coordinate < middle {
                let child = self.change(self.left[root], low, middle, coordinate, delta);
                self.left[root] = child;
            } else {
                let child = self.change(self.right[root], middle, high, coordinate, delta);
                self.right[root] = child;
            }
        }
        root
    }

    fn apply(&mut self, n: usize, position: usize, value: i64, delta: i32) {
        let mut node = position + 1;
        while node <= n {
            let root = self.change(self.roots[node], 0, VALUE_COUNT,
                                   (value + 30) as usize, delta);
            self.roots[node] = root;
            node += node & node.wrapping_neg();
        }
    }
}

#[no_mangle]
pub extern "C" fn fenwick_weighted_segment_tree_range_kth(
    input: *const i64, length: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > 79 { return i64::MIN; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if !(1..=MAX_N as i64).contains(&values[0]) || !(0..=MAX_Q as i64).contains(&values[1]) {
        return i64::MIN;
    }
    let (n, q) = (values[0] as usize, values[1] as usize);
    if length != 2 + n + 4 * q { return i64::MIN; }

    let mut current = [0i64; MAX_N];
    let mut pool = Pool {
        left: [0; NODE_CAPACITY + 1],
        right: [0; NODE_CAPACITY + 1],
        count: [0; NODE_CAPACITY + 1],
        roots: [0; MAX_N + 1],
        used: 0,
    };
    for position in 0..n {
        let value = values[2 + position];
        if !(-30..=30).contains(&value) { return i64::MIN; }
        current[position] = value;
        pool.apply(n, position, value, 1);
    }

    let (mut checksum, mut query_number) = (0i64, 0i64);
    let mut cursor = 2 + n;
    for _ in 0..q {
        let (opcode, first, second, third) =
            (values[cursor], values[cursor + 1], values[cursor + 2], values[cursor + 3]);
        cursor += 4;
        if opcode == 0 {
            if first < 0 || first >= n as i64 || !(-30..=30).contains(&second) || third != 0 {
                return i64::MIN;
            }
            let position = first as usize;
            pool.apply(n, position, current[position], -1);
            current[position] = second;
            pool.apply(n, position, current[position], 1);
        } else if opcode == 1 {
            if first < 0 || first >= second || second > n as i64 || third < 1 || third > second - first {
                return i64::MIN;
            }
            let mut left_roots = [0usize; MAX_N + 1];
            let mut right_roots = [0usize; MAX_N + 1];
            let (mut left_size, mut right_size) = (0usize, 0usize);
            let mut node = first as usize;
            while node > 0 {
                left_roots[left_size] = pool.roots[node];
                left_size += 1;
                node &= node - 1;
            }
            node = second as usize;
            while node > 0 {
                right_roots[right_size] = pool.roots[node];
                right_size += 1;
                node &= node - 1;
            }
            let (mut low, mut high, mut rank) = (0usize, VALUE_COUNT, third as i32);
            while high - low > 1 {
                let middle = (low + high) / 2;
                let mut left_count = 0i32;
                for i in 0..right_size { left_count += pool.count[pool.left[right_roots[i]]]; }
                for i in 0..left_size { left_count -= pool.count[pool.left[left_roots[i]]]; }
                if rank <= left_count {
                    for i in 0..right_size { right_roots[i] = pool.left[right_roots[i]]; }
                    for i in 0..left_size { left_roots[i] = pool.left[left_roots[i]]; }
                    high = middle;
                } else {
                    rank -= left_count;
                    for i in 0..right_size { right_roots[i] = pool.right[right_roots[i]]; }
                    for i in 0..left_size { left_roots[i] = pool.right[left_roots[i]]; }
                    low = middle;
                }
            }
            query_number += 1;
            checksum += query_number * (low as i64 - 30);
        } else {
            return i64::MIN;
        }
    }
    checksum
}
