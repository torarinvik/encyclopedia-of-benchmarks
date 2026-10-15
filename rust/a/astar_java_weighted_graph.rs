const MAX_VERTICES: usize = 7;
const MAX_STATES: usize = 4096;

#[derive(Clone, Copy)]
struct SearchState {
    distance: i32,
    heuristic: i32,
    length: usize,
    path: [i32; MAX_VERTICES],
}

unsafe fn write_i64(output: *mut u8, offset: usize, value: i64) {
    for (index, byte) in value.to_le_bytes().iter().enumerate() {
        *output.add(offset + index) = *byte;
    }
}

#[no_mangle]
pub unsafe extern "C" fn astar_java_weighted_graph(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 5 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n64 = values[0];
    let m64 = values[1];
    let start64 = values[2];
    let target64 = values[3];
    if !(1..=7).contains(&n64) || !(0..=16).contains(&m64)
        || start64 < 0 || start64 >= n64 || target64 < 0 || target64 >= n64
        || length != 4 + n64 as usize + 3 * m64 as usize { return -1; }
    let n = n64 as usize;
    let m = m64 as usize;
    let start = start64 as usize;
    let target = target64 as usize;
    let mut heuristic = [0i32; MAX_VERTICES];
    let mut adjacent = [[0i32; MAX_VERTICES]; MAX_VERTICES];
    let mut weights = [[0i32; MAX_VERTICES]; MAX_VERTICES];
    let mut degree = [0usize; MAX_VERTICES];
    for i in 0..n {
        if !(-1000..=1000).contains(&values[4 + i]) { return -1; }
        heuristic[i] = values[4 + i] as i32;
    }
    let mut position = 4 + n;
    for _ in 0..m {
        let u64 = values[position];
        let v64 = values[position + 1];
        let weight64 = values[position + 2];
        position += 3;
        if u64 < 0 || u64 >= n64 || v64 < 0 || v64 >= n64 || u64 == v64
            || !(0..=1000).contains(&weight64) { return -1; }
        let u = u64 as usize;
        let v = v64 as usize;
        if (0..degree[u]).any(|i| adjacent[u][i] == v as i32) { return -1; }
        adjacent[u][degree[u]] = v as i32;
        weights[u][degree[u]] = weight64 as i32;
        degree[u] += 1;
        adjacent[v][degree[v]] = u as i32;
        weights[v][degree[v]] = weight64 as i32;
        degree[v] += 1;
    }
    let empty = SearchState { distance: 0, heuristic: 0, length: 0, path: [0; MAX_VERTICES] };
    let mut states = [empty; MAX_STATES];
    let mut heap = [0usize; MAX_STATES];
    let mut state_count = 1usize;
    let mut heap_size = 1usize;
    states[0].heuristic = heuristic[start];
    states[0].length = 1;
    states[0].path[0] = start as i32;
    heap[0] = 0;
    let mut found = false;
    let mut solution = 0usize;
    while heap_size > 0 {
        let current_index = heap[0];
        let last = heap[heap_size - 1];
        heap_size -= 1;
        if heap_size > 0 {
            let mut i = 0usize;
            let half = heap_size / 2;
            while i < half {
                let mut child = 2 * i + 1;
                let mut child_index = heap[child];
                let right = child + 1;
                if right < heap_size
                    && states[heap[right]].distance + states[heap[right]].heuristic
                        < states[child_index].distance + states[child_index].heuristic {
                    child = right;
                    child_index = heap[right];
                }
                if states[last].distance + states[last].heuristic
                    <= states[child_index].distance + states[child_index].heuristic { break; }
                heap[i] = child_index;
                i = child;
            }
            heap[i] = last;
        }
        let current = states[current_index];
        let current_vertex = current.path[current.length - 1] as usize;
        if current_vertex == target { found = true; solution = current_index; break; }
        for edge in 0..degree[current_vertex] {
            let next = adjacent[current_vertex][edge] as usize;
            if current.path[..current.length].contains(&(next as i32)) { continue; }
            if state_count >= MAX_STATES || heap_size >= MAX_STATES { return -1; }
            let mut child_state = empty;
            child_state.distance = current.distance + weights[current_vertex][edge];
            child_state.heuristic = heuristic[next];
            child_state.length = current.length + 1;
            child_state.path[..current.length].copy_from_slice(&current.path[..current.length]);
            child_state.path[current.length] = next as i32;
            states[state_count] = child_state;
            let next_state = state_count;
            state_count += 1;
            let mut i = heap_size;
            heap_size += 1;
            while i > 0 {
                let parent = (i - 1) / 2;
                let parent_index = heap[parent];
                if states[parent_index].distance + states[parent_index].heuristic
                    <= child_state.distance + child_state.heuristic { break; }
                heap[i] = parent_index;
                i = parent;
            }
            heap[i] = next_state;
        }
    }
    let mut result = [0i64; 3 + MAX_VERTICES];
    let mut result_words = 3usize;
    if !found {
        result[0] = -1; result[1] = -1; result[2] = 0;
    } else {
        let state = states[solution];
        result[0] = state.distance as i64;
        result[1] = state.heuristic as i64;
        result[2] = state.length as i64;
        result_words += state.length;
        for i in 0..state.length { result[3 + i] = state.path[i] as i64; }
    }
    let output_bytes = result_words * 8;
    if output.is_null() || capacity < output_bytes { return -2; }
    for i in 0..result_words { write_i64(output, i * 8, result[i]); }
    output_bytes as i64
}
