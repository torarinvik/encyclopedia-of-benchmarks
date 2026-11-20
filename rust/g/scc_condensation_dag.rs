const MAX_N: usize = 8;
const MAX_M: usize = 28;
const MAX_INPUT_LENGTH: usize = 58;
const MAX_OUTPUT_BYTES: usize = 17;

#[no_mangle]
pub unsafe extern "C" fn scc_condensation_dag(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 0 || values[0] > MAX_N as i64 || values[1] < 0 || values[1] > MAX_M as i64 { return -1; }
    let n = values[0] as usize;
    let m = values[1] as usize;
    if length != 2 + 2 * m { return -1; }
    let mut adjacency = [0u16; MAX_N];
    let mut reverse = [0u16; MAX_N];
    for i in 0..m {
        let source = values[2 + 2 * i];
        let target = values[3 + 2 * i];
        if source < 0 || source >= n as i64 || target < 0 || target >= n as i64 { return -1; }
        adjacency[source as usize] |= 1u16 << target;
        reverse[target as usize] |= 1u16 << source;
    }

    let mut visited = [false; MAX_N];
    let mut order = [0u8; MAX_N];
    let mut stack_vertex = [0u8; MAX_N];
    let mut stack_next = [0u8; MAX_N];
    let mut order_count = 0usize;
    for start in 0..n {
        if visited[start] { continue; }
        let mut stack_size = 1usize;
        stack_vertex[0] = start as u8;
        stack_next[0] = 0;
        visited[start] = true;
        while stack_size > 0 {
            let frame = stack_size - 1;
            let vertex = stack_vertex[frame] as usize;
            let mut candidate = stack_next[frame] as usize;
            while candidate < n && adjacency[vertex] & (1u16 << candidate) == 0 { candidate += 1; }
            if candidate < n {
                stack_next[frame] = (candidate + 1) as u8;
                if !visited[candidate] {
                    visited[candidate] = true;
                    stack_vertex[stack_size] = candidate as u8;
                    stack_next[stack_size] = 0;
                    stack_size += 1;
                }
            } else {
                order[order_count] = vertex as u8;
                order_count += 1;
                stack_size -= 1;
            }
        }
    }

    let mut raw_component = [-1i8; MAX_N];
    visited.fill(false);
    let mut component_count = 0usize;
    while order_count > 0 {
        order_count -= 1;
        let start = order[order_count] as usize;
        if visited[start] { continue; }
        let mut stack_size = 1usize;
        stack_vertex[0] = start as u8;
        visited[start] = true;
        raw_component[start] = component_count as i8;
        while stack_size > 0 {
            stack_size -= 1;
            let vertex = stack_vertex[stack_size] as usize;
            for next in 0..n {
                if reverse[vertex] & (1u16 << next) != 0 && !visited[next] {
                    visited[next] = true;
                    raw_component[next] = component_count as i8;
                    stack_vertex[stack_size] = next as u8;
                    stack_size += 1;
                }
            }
        }
        component_count += 1;
    }

    let mut minimum = [n as u8; MAX_N];
    let mut raw_order = [0u8; MAX_N];
    let mut canonical = [0u8; MAX_N];
    let mut labels = [0u8; MAX_N];
    let mut row_mask = [0u8; MAX_N];
    for component in 0..component_count { raw_order[component] = component as u8; }
    for vertex in 0..n {
        let component = raw_component[vertex] as usize;
        minimum[component] = minimum[component].min(vertex as u8);
    }
    for i in 1..component_count {
        let key = raw_order[i];
        let mut j = i;
        while j > 0 && minimum[raw_order[j - 1] as usize] > minimum[key as usize] {
            raw_order[j] = raw_order[j - 1];
            j -= 1;
        }
        raw_order[j] = key;
    }
    for i in 0..component_count { canonical[raw_order[i] as usize] = i as u8; }
    for vertex in 0..n { labels[vertex] = canonical[raw_component[vertex] as usize]; }
    for source in 0..n {
        for target in 0..n {
            if adjacency[source] & (1u16 << target) == 0 { continue; }
            let left = labels[source];
            let right = labels[target];
            if left != right { row_mask[left as usize] |= 1u8 << right; }
        }
    }

    let mut staged = [0u8; MAX_OUTPUT_BYTES];
    staged[0] = component_count as u8;
    for vertex in 0..n { staged[1 + vertex] = labels[vertex]; }
    for component in 0..component_count { staged[1 + n + component] = row_mask[component]; }
    let output_size = 1 + n + component_count;
    if output.is_null() || capacity < output_size { return -2; }
    for i in 0..output_size { *output.add(i) = staged[i]; }
    output_size as i64
}
