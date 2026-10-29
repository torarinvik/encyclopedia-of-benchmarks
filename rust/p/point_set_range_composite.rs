const MODULUS: i64 = 998_244_353;
const MAX_N: usize = 16;
const MAX_OPERATIONS: usize = 32;
const MAX_INPUT_LENGTH: usize = 162;
const TREE_CAPACITY: usize = 64;

#[derive(Clone, Copy)]
struct AffineMap {
    a: i64,
    b: i64,
}

const IDENTITY: AffineMap = AffineMap { a: 1, b: 0 };

fn compose(left: AffineMap, right: AffineMap) -> AffineMap {
    AffineMap {
        a: (right.a * left.a) % MODULUS,
        b: (right.a * left.b + right.b) % MODULUS,
    }
}

#[no_mangle]
pub unsafe extern "C" fn point_set_range_composite(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if values[0] < 1 || values[0] > MAX_N as i64 ||
        values[1] < 0 || values[1] > MAX_OPERATIONS as i64 {
        return -1;
    }
    let n = values[0] as usize;
    let q = values[1] as usize;
    if length != 2 + 2 * n + 4 * q {
        return -1;
    }

    for index in 0..n {
        let a = values[2 + 2 * index];
        let b = values[3 + 2 * index];
        if !(0..MODULUS).contains(&a) || !(0..MODULUS).contains(&b) {
            return -1;
        }
    }

    let mut base = 1;
    while base < n {
        base *= 2;
    }
    let mut tree = [IDENTITY; TREE_CAPACITY];
    for index in 0..n {
        tree[base + index] = AffineMap {
            a: values[2 + 2 * index],
            b: values[3 + 2 * index],
        };
    }
    for node in (1..base).rev() {
        tree[node] = compose(tree[2 * node], tree[2 * node + 1]);
    }

    let mut checksum = 0_i64;
    let mut query_number = 0_i64;
    let mut cursor = 2 + 2 * n;
    for _ in 0..q {
        let opcode = values[cursor];
        let first = values[cursor + 1];
        let second = values[cursor + 2];
        let third = values[cursor + 3];
        cursor += 4;
        if opcode == 0 {
            if first < 0 || first >= n as i64 ||
                !(0..MODULUS).contains(&second) || !(0..MODULUS).contains(&third) {
                return -1;
            }
            let mut node = base + first as usize;
            tree[node] = AffineMap { a: second, b: third };
            while node > 1 {
                node /= 2;
                tree[node] = compose(tree[2 * node], tree[2 * node + 1]);
            }
        } else if opcode == 1 {
            if first < 0 || first > second || second > n as i64 ||
                !(0..MODULUS).contains(&third) {
                return -1;
            }
            let mut left_index = base + first as usize;
            let mut right_index = base + second as usize;
            let (mut left, mut right) = (IDENTITY, IDENTITY);
            while left_index < right_index {
                if left_index & 1 == 1 {
                    left = compose(left, tree[left_index]);
                    left_index += 1;
                }
                if right_index & 1 == 1 {
                    right_index -= 1;
                    right = compose(tree[right_index], right);
                }
                left_index /= 2;
                right_index /= 2;
            }
            let range = compose(left, right);
            let answer = (range.a * third + range.b) % MODULUS;
            query_number += 1;
            checksum = (checksum + query_number * answer) % MODULUS;
        } else {
            return -1;
        }
    }
    if cursor == length { checksum } else { -1 }
}
