const MIN_SIZE: i64 = 2;
const MAX_SIZE: i64 = 1024;
const MAX_NODES: usize = 1023;
const MODULUS: i32 = 10000;
const MULTIPLIER: i32 = 31415821;
const VALUE_RANGE: i32 = 100;

#[derive(Clone, Copy)]
struct Node {
    value: i32,
    left: i32,
    right: i32,
}

fn multiply(p: i32, q: i32) -> i32 {
    let p_high = p / MODULUS;
    let p_low = p % MODULUS;
    let q_high = q / MODULUS;
    let q_low = q % MODULUS;
    ((p_low * q_high + p_high * q_low) % MODULUS) * MODULUS + p_low * q_low
}

fn next_random(seed: i32) -> i32 { multiply(seed, MULTIPLIER) + 1 }

fn skip_random(mut seed: i32, count: i32) -> i32 {
    for _ in 0..count { seed = next_random(seed); }
    seed
}

fn make_tree(nodes: &mut [Node; MAX_NODES], used: &mut usize,
             size: i32, seed_value: i32) -> i32 {
    if size <= 1 { return -1; }
    let seed = next_random(seed_value);
    let index = *used as i32;
    *used += 1;
    nodes[index as usize].value = seed % VALUE_RANGE;
    let half = size / 2;
    nodes[index as usize].left = make_tree(nodes, used, half, seed);
    nodes[index as usize].right = make_tree(nodes, used, half, skip_random(seed, size + 1));
    index
}

fn swap_left(nodes: &mut [Node; MAX_NODES], left: i32, right: i32,
             left_left: i32, right_left: i32, left_value: i32, right_value: i32) {
    nodes[right as usize].value = left_value;
    nodes[right as usize].left = left_left;
    nodes[left as usize].left = right_left;
    nodes[left as usize].value = right_value;
}

fn swap_right(nodes: &mut [Node; MAX_NODES], left: i32, right: i32,
              left_right: i32, right_right: i32, left_value: i32, right_value: i32) {
    nodes[right as usize].value = left_value;
    nodes[right as usize].right = left_right;
    nodes[left as usize].right = right_right;
    nodes[left as usize].value = right_value;
}

fn merge(nodes: &mut [Node; MAX_NODES], root: i32,
         mut spill: i32, direction: i32) -> i32 {
    let mut root_value = nodes[root as usize].value;
    let mut left = nodes[root as usize].left;
    let mut right = nodes[root as usize].right;
    let right_exchange = (root_value > spill) != (direction != 0);
    if right_exchange {
        nodes[root as usize].value = spill;
        spill = root_value;
    }
    while left >= 0 {
        let left_value = nodes[left as usize].value;
        let left_left = nodes[left as usize].left;
        let left_right = nodes[left as usize].right;
        let right_value = nodes[right as usize].value;
        let right_left = nodes[right as usize].left;
        let right_right = nodes[right as usize].right;
        let element_exchange = (left_value > right_value) != (direction != 0);
        if right_exchange {
            if element_exchange {
                swap_right(nodes, left, right, left_right, right_right, left_value, right_value);
                left = left_left;
                right = right_left;
            } else {
                left = left_right;
                right = right_right;
            }
        } else if element_exchange {
            swap_left(nodes, left, right, left_left, right_left, left_value, right_value);
            left = left_right;
            right = right_right;
        } else {
            left = left_left;
            right = right_left;
        }
    }
    if nodes[root as usize].left >= 0 {
        let left_root = nodes[root as usize].left;
        let right_root = nodes[root as usize].right;
        root_value = nodes[root as usize].value;
        nodes[root as usize].value = merge(nodes, left_root, root_value, direction);
        spill = merge(nodes, right_root, spill, direction);
    }
    spill
}

fn sort_tree(nodes: &mut [Node; MAX_NODES], root: i32,
             mut spill: i32, direction: i32) -> i32 {
    if nodes[root as usize].left < 0 {
        if (nodes[root as usize].value > spill) != (direction != 0) {
            let value = nodes[root as usize].value;
            nodes[root as usize].value = spill;
            spill = value;
        }
        return spill;
    }
    let left = nodes[root as usize].left;
    let right = nodes[root as usize].right;
    let value = nodes[root as usize].value;
    nodes[root as usize].value = sort_tree(nodes, left, value, direction);
    spill = sort_tree(nodes, right, spill, if direction == 0 { 1 } else { 0 });
    merge(nodes, root, spill, direction)
}

fn checksum(nodes: &[Node; MAX_NODES], index: i32,
            position: &mut i64, sum: &mut i64) {
    if index < 0 { return; }
    checksum(nodes, nodes[index as usize].left, position, sum);
    *position += 1;
    *sum += *position * i64::from(nodes[index as usize].value);
    checksum(nodes, nodes[index as usize].right, position, sum);
}

#[no_mangle]
pub extern "C" fn bisort(size: i64) -> i64 {
    if !(MIN_SIZE..=MAX_SIZE).contains(&size) { return -1; }
    let empty = Node { value: 0, left: -1, right: -1 };
    let mut nodes = [empty; MAX_NODES];
    let mut used = 0;
    let root = make_tree(&mut nodes, &mut used, size as i32, 12345768);
    let mut spill = next_random(245867) % VALUE_RANGE;
    spill = sort_tree(&mut nodes, root, spill, 0);
    spill = sort_tree(&mut nodes, root, spill, 1);
    let mut position = 0_i64;
    let mut sum = 0_i64;
    checksum(&nodes, root, &mut position, &mut sum);
    position += 1;
    sum + position * i64::from(spill)
}
