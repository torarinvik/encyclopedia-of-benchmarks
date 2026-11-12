const MAX_Q: usize = 64;
const MAX_BITS: usize = 30;
const MAX_NODES: usize = 1 + MAX_BITS * MAX_Q;
const MAX_INPUT_VALUES: usize = 1 + 2 * MAX_Q;

fn find_or_create_child(
    children: &mut [[i32; 2]; MAX_NODES],
    node_count: &mut usize,
    node: usize,
    direction: usize,
) -> usize {
    let mut child = children[node][direction];
    if child < 0 {
        child = *node_count as i32;
        *node_count += 1;
        children[child as usize] = [-1, -1];
        children[node][direction] = child;
    }
    child as usize
}

fn insert_value(
    children: &mut [[i32; 2]; MAX_NODES],
    count: &mut [i32; MAX_NODES],
    node_count: &mut usize,
    value: u32,
) {
    let mut path = [0usize; MAX_BITS + 1];
    let mut node = 0usize;
    for depth in 0..MAX_BITS {
        let bit = MAX_BITS - 1 - depth;
        node = find_or_create_child(children, node_count, node, ((value >> bit) & 1) as usize);
        path[depth + 1] = node;
    }
    if count[node] != 0 {
        return;
    }
    for item in path {
        count[item] += 1;
    }
}

fn remove_value(children: &[[i32; 2]; MAX_NODES], count: &mut [i32; MAX_NODES], value: u32) {
    let mut path = [0usize; MAX_BITS + 1];
    let mut node = 0usize;
    for depth in 0..MAX_BITS {
        let bit = MAX_BITS - 1 - depth;
        let child = children[node][((value >> bit) & 1) as usize];
        if child < 0 {
            return;
        }
        node = child as usize;
        path[depth + 1] = node;
    }
    if count[node] == 0 {
        return;
    }
    for item in path {
        count[item] -= 1;
    }
}

fn minimum_xor(children: &[[i32; 2]; MAX_NODES], count: &[i32; MAX_NODES], value: u32) -> u32 {
    let mut node = 0usize;
    let mut result = 0u32;
    for bit in (0..MAX_BITS).rev() {
        let preferred = ((value >> bit) & 1) as usize;
        let child = children[node][preferred];
        if child >= 0 && count[child as usize] > 0 {
            node = child as usize;
        } else {
            result |= 1u32 << bit;
            node = children[node][preferred ^ 1] as usize;
        }
    }
    result
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn set_xor_min(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT_VALUES {
        return -1;
    }
    let q_value = *input;
    if q_value < 1 || q_value > MAX_Q as i64 {
        return -1;
    }
    let q = q_value as usize;
    if length != 1 + 2 * q {
        return -1;
    }
    let upper_bound = 1i64 << MAX_BITS;
    for operation in 0..q {
        let offset = 1 + 2 * operation;
        let kind = *input.add(offset);
        let value = *input.add(offset + 1);
        if !(0..=2).contains(&kind) || !(0..upper_bound).contains(&value) {
            return -1;
        }
    }

    let mut children = [[-1i32; 2]; MAX_NODES];
    let mut count = [0i32; MAX_NODES];
    let mut node_count = 1usize;
    let mut answers = [0i64; MAX_Q];
    let mut answer_count = 0usize;
    for operation in 0..q {
        let offset = 1 + 2 * operation;
        let kind = *input.add(offset);
        let value = *input.add(offset + 1) as u32;
        if kind == 0 {
            insert_value(&mut children, &mut count, &mut node_count, value);
        } else if kind == 1 {
            remove_value(&children, &mut count, value);
        } else {
            if count[0] == 0 {
                return -1;
            }
            answers[answer_count] = minimum_xor(&children, &count, value) as i64;
            answer_count += 1;
        }
    }
    let required = 8 * answer_count;
    if output.is_null() || capacity < required {
        return -2;
    }
    for index in 0..answer_count {
        store_i64_le(output, 8 * index, answers[index]);
    }
    required as i64
}
