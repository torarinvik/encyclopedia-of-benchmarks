const MAX_N: usize = 64;
const MAX_M: usize = MAX_N * (MAX_N - 1) / 2;
const MAX_INPUT_VALUES: usize = 2 + 2 * MAX_M;
const MAX_OUTPUT_VALUES: usize = 1 + 2 * MAX_N;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn connected_components_of_complement_graph(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_VALUES {
        return -1;
    }
    let n_value = *input;
    let m_value = *input.add(1);
    if n_value < 1 || n_value > MAX_N as i64 || m_value < 0
        || m_value > n_value * (n_value - 1) / 2
    {
        return -1;
    }
    let n = n_value as usize;
    let m = m_value as usize;
    if length != 2 + 2 * m {
        return -1;
    }

    let mut graph = [0u64; MAX_N];
    for edge in 0..m {
        let left_value = *input.add(2 + 2 * edge);
        let right_value = *input.add(3 + 2 * edge);
        if left_value < 0 || left_value >= n_value || right_value < 0
            || right_value >= n_value || left_value == right_value
        {
            return -1;
        }
        let left = left_value as usize;
        let right = right_value as usize;
        let bit = 1u64 << right;
        if graph[left] & bit != 0 {
            return -1;
        }
        graph[left] |= bit;
        graph[right] |= 1u64 << left;
    }

    let mut remaining = [0usize; MAX_N];
    let mut queue = [0usize; MAX_N];
    let mut label = [-1i64; MAX_N];
    for vertex in 0..n {
        remaining[vertex] = vertex;
    }
    let mut remaining_count = n;
    let mut component_count = 0usize;
    while remaining_count > 0 {
        remaining_count -= 1;
        let root = remaining[remaining_count];
        label[root] = component_count as i64;
        let mut head = 0usize;
        let mut tail = 0usize;
        queue[tail] = root;
        tail += 1;
        while head < tail {
            let vertex = queue[head];
            head += 1;
            let mut position = 0usize;
            while position < remaining_count {
                let candidate = remaining[position];
                if (graph[vertex] >> candidate) & 1 != 0 {
                    position += 1;
                } else {
                    remaining_count -= 1;
                    remaining[position] = remaining[remaining_count];
                    label[candidate] = component_count as i64;
                    queue[tail] = candidate;
                    tail += 1;
                }
            }
        }
        component_count += 1;
    }

    let mut staged = [0i64; MAX_OUTPUT_VALUES];
    let mut used = 0usize;
    staged[used] = component_count as i64;
    used += 1;
    let mut emitted = [false; MAX_N];
    for first in 0..n {
        let component = label[first] as usize;
        if emitted[component] {
            continue;
        }
        emitted[component] = true;
        let mut component_size = 0usize;
        for vertex in 0..n {
            if label[vertex] as usize == component {
                component_size += 1;
            }
        }
        staged[used] = component_size as i64;
        used += 1;
        for vertex in 0..n {
            if label[vertex] as usize == component {
                staged[used] = vertex as i64;
                used += 1;
            }
        }
    }

    let required = 8 * used;
    if output.is_null() || capacity < required {
        return -2;
    }
    for index in 0..used {
        store_i64_le(output, 8 * index, staged[index]);
    }
    required as i64
}
