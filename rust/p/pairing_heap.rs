const MAX_ITEMS: usize = 128;
const MAX_PARSEABLE_INPUT_LENGTH: usize = MAX_ITEMS + 2;
const FNV_OFFSET_BASIS: u64 = 14695981039346656037;
const FNV_PRIME: u64 = 1099511628211;

#[derive(Clone, Copy)]
struct PairingNode {
    key: i32,
    first_child: isize,
    next_sibling: isize,
}

fn meld(mut first: isize, mut second: isize, nodes: &mut [PairingNode; MAX_ITEMS]) -> isize {
    if first < 0 { return second; }
    if second < 0 { return first; }
    if nodes[second as usize].key < nodes[first as usize].key {
        std::mem::swap(&mut first, &mut second);
    }
    let first_index = first as usize;
    let second_index = second as usize;
    nodes[second_index].next_sibling = nodes[first_index].first_child;
    nodes[first_index].first_child = second;
    nodes[first_index].next_sibling = -1;
    first
}

fn hash_key(mut hash: u64, key: i32) -> u64 {
    for byte in key.to_le_bytes() {
        hash = (hash ^ u64::from(byte)).wrapping_mul(FNV_PRIME);
    }
    hash
}

#[no_mangle]
pub unsafe extern "C" fn pairing_heap(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH {
        return -1;
    }
    let input = std::slice::from_raw_parts(values, length);
    let raw_count = input[0];
    if raw_count < 2
        || raw_count > MAX_ITEMS as i64
        || length != 1 + raw_count as usize
    {
        return -1;
    }
    let count = raw_count as usize;
    let mut nodes = [PairingNode { key: 0, first_child: -1, next_sibling: -1 }; MAX_ITEMS];
    for index in 0..count {
        let value = input[1 + index];
        if value < i32::MIN as i64 || value > i32::MAX as i64 {
            return -1;
        }
        if input[1..1 + index].contains(&value) {
            return -1;
        }
        nodes[index].key = value as i32;
    }

    let mut root = -1isize;
    for index in 0..count {
        root = meld(root, index as isize, &mut nodes);
    }

    let mut hash = FNV_OFFSET_BASIS;
    for _ in 0..count - 1 {
        let removed = root as usize;
        hash = hash_key(hash, nodes[removed].key);
        let mut forest = [-1isize; MAX_ITEMS];
        let mut paired = [-1isize; MAX_ITEMS];
        let mut forest_count = 0usize;
        let mut child = nodes[removed].first_child;
        nodes[removed].first_child = -1;
        while child >= 0 {
            let child_index = child as usize;
            let next = nodes[child_index].next_sibling;
            nodes[child_index].next_sibling = -1;
            forest[forest_count] = child;
            forest_count += 1;
            child = next;
        }
        let mut paired_count = 0usize;
        let mut index = 0usize;
        while index < forest_count {
            let right = if index + 1 < forest_count { forest[index + 1] } else { -1 };
            paired[paired_count] = meld(forest[index], right, &mut nodes);
            paired_count += 1;
            index += 2;
        }
        let mut rebuilt = -1isize;
        while paired_count > 0 {
            paired_count -= 1;
            rebuilt = meld(rebuilt, paired[paired_count], &mut nodes);
        }
        root = rebuilt;
    }
    (hash & i64::MAX as u64) as i64
}
