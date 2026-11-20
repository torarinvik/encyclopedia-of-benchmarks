const MAX_N: usize = 20;
const MAX_Q: usize = 20;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 123;
const TREE_BASE: usize = 32;
const TREE_SIZE: usize = 2 * TREE_BASE;
const BASE: i64 = 911_382_323;
const MODULUS: i64 = 1_000_000_007;

#[derive(Clone, Copy, Default)]
struct HashNode {
    hash: i64,
    length: usize,
}

fn combine(left: HashNode, right: HashNode, powers: &[i64; MAX_N + 1]) -> HashNode {
    HashNode {
        hash: (left.hash * powers[right.length] + right.hash) % MODULUS,
        length: left.length + right.length,
    }
}

fn range_hash(
    tree: &[HashNode; TREE_SIZE],
    powers: &[i64; MAX_N + 1],
    left: usize,
    right: usize,
) -> HashNode {
    let mut left_index = TREE_BASE + left;
    let mut right_index = TREE_BASE + right;
    let mut left_result = HashNode::default();
    let mut right_result = HashNode::default();
    while left_index < right_index {
        if left_index % 2 == 1 {
            left_result = combine(left_result, tree[left_index], powers);
            left_index += 1;
        }
        if right_index % 2 == 1 {
            right_index -= 1;
            right_result = combine(tree[right_index], right_result, powers);
        }
        left_index /= 2;
        right_index /= 2;
    }
    combine(left_result, right_result, powers)
}

fn set_symbol(
    tree: &mut [HashNode; TREE_SIZE],
    powers: &[i64; MAX_N + 1],
    index: usize,
    symbol: i64,
) {
    let mut node = TREE_BASE + index;
    tree[node] = HashNode { hash: symbol, length: 1 };
    node /= 2;
    while node > 0 {
        tree[node] = combine(tree[2 * node], tree[2 * node + 1], powers);
        node /= 2;
    }
}

fn execute(words: &[i64]) -> i64 {
    if words.len() < 2 || words.len() > MAX_PARSEABLE_INPUT_LENGTH {
        return -1;
    }
    let (n_value, q_value) = (words[0], words[1]);
    if !(0..=MAX_N as i64).contains(&n_value) || !(0..=MAX_Q as i64).contains(&q_value) {
        return -1;
    }
    let (n, q) = (n_value as usize, q_value as usize);
    if words.len() != 2 + n + 5 * q {
        return -1;
    }
    let symbol_start = 2;
    let query_start = symbol_start + n;
    for &symbol in &words[symbol_start..query_start] {
        if !(0..=25).contains(&symbol) {
            return -1;
        }
    }

    let mut powers = [0i64; MAX_N + 1];
    powers[0] = 1;
    for exponent in 1..=MAX_N {
        powers[exponent] = powers[exponent - 1] * BASE % MODULUS;
    }
    let mut tree = [HashNode::default(); TREE_SIZE];
    for index in 0..n {
        tree[TREE_BASE + index] = HashNode {
            hash: words[symbol_start + index],
            length: 1,
        };
    }
    for node in (1..TREE_BASE).rev() {
        tree[node] = combine(tree[2 * node], tree[2 * node + 1], &powers);
    }

    let mut score = 0i64;
    for operation in 0..q {
        let offset = query_start + 5 * operation;
        let opcode = words[offset];
        let (a, b, c, d) = (words[offset + 1], words[offset + 2], words[offset + 3], words[offset + 4]);
        let response: i64;
        if opcode == 0 {
            if a < 0 || a >= n_value || !(0..=25).contains(&b) || c != 0 || d != 0 {
                return -1;
            }
            set_symbol(&mut tree, &powers, a as usize, b);
            response = 0;
        } else if opcode == 1 {
            if a < 0 || a > b || b > n_value || c < 0 || c > d || d > n_value {
                return -1;
            }
            if b - a != d - c {
                response = 0;
            } else {
                let first = range_hash(&tree, &powers, a as usize, b as usize);
                let second = range_hash(&tree, &powers, c as usize, d as usize);
                response = if first.hash == second.hash { 1 } else { 0 };
            }
        } else {
            return -1;
        }
        score += (operation as i64 + 1) * (opcode * 2 + response + 1);
    }
    score
}

#[no_mangle]
pub unsafe extern "C" fn rolling_hash_on_segment_tree_trace(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH {
        return -1;
    }
    execute(std::slice::from_raw_parts(input, length))
}
