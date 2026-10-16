/// Push–Relabel maximum flow for bounded multi-terminal integral networks.
const MAX_VERTICES: usize = 14;
const AUGMENTED_VERTICES: usize = 16;
const MAX_INPUT_LENGTH: usize = 227;
const MAX_CAPACITY: i64 = 1_000_000;

#[no_mangle]
pub extern "C" fn push_relabel(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT_LENGTH { return -1; }
    let n64 = unsafe { *input };
    let source_count64 = unsafe { *input.add(1) };
    if n64 < 2 || n64 > MAX_VERTICES as i64 || source_count64 < 1 || source_count64 >= n64 { return -1; }
    let n = n64 as usize;
    let source_count = source_count64 as usize;
    let sink_count_index = 2 + source_count;
    if length <= sink_count_index { return -1; }

    let mut is_source = [false; MAX_VERTICES];
    let mut is_sink = [false; MAX_VERTICES];
    let mut sources = [0usize; MAX_VERTICES];
    for index in 0..source_count {
        let node64 = unsafe { *input.add(2 + index) };
        if node64 < 0 || node64 >= n64 || is_source[node64 as usize] { return -1; }
        sources[index] = node64 as usize;
        is_source[node64 as usize] = true;
    }
    let sink_count64 = unsafe { *input.add(sink_count_index) };
    if sink_count64 < 1 || sink_count64 > n64 - source_count64 { return -1; }
    let sink_count = sink_count64 as usize;
    let matrix_start = sink_count_index + 1 + sink_count;
    if length < matrix_start || length != matrix_start + n * n { return -1; }
    for index in 0..sink_count {
        let node64 = unsafe { *input.add(sink_count_index + 1 + index) };
        if node64 < 0 || node64 >= n64 || is_sink[node64 as usize] || is_source[node64 as usize] { return -1; }
        is_sink[node64 as usize] = true;
    }

    let mut residual = [0i64; AUGMENTED_VERTICES * AUGMENTED_VERTICES];
    let mut source_out = [0i64; MAX_VERTICES];
    let mut flow_limit = 0i64;
    for row in 0..n {
        for column in 0..n {
            let capacity = unsafe { *input.add(matrix_start + row * n + column) };
            if capacity < 0 || capacity > MAX_CAPACITY || (row == column && capacity != 0) { return -1; }
            residual[row * AUGMENTED_VERTICES + column] = capacity;
            if is_source[row] {
                source_out[row] += capacity;
                flow_limit += capacity;
            }
        }
    }

    let super_source = n;
    let super_sink = n + 1;
    for index in 0..source_count {
        residual[super_source * AUGMENTED_VERTICES + sources[index]] = source_out[sources[index]];
    }
    for index in 0..sink_count {
        let sink = unsafe { *input.add(sink_count_index + 1 + index) as usize };
        residual[sink * AUGMENTED_VERTICES + super_sink] = flow_limit;
    }

    let mut height = [0i32; AUGMENTED_VERTICES];
    let mut excess = [0i64; AUGMENTED_VERTICES];
    let mut active = [false; AUGMENTED_VERTICES];
    height[super_source] = n as i32 + 2;
    for index in 0..source_count {
        let source = sources[index];
        let initial_excess = residual[super_source * AUGMENTED_VERTICES + source];
        residual[super_source * AUGMENTED_VERTICES + source] = 0;
        residual[source * AUGMENTED_VERTICES + super_source] += initial_excess;
        excess[source] += initial_excess;
        if excess[source] > 0 { active[source] = true; }
    }

    loop {
        let mut node = 0usize;
        while node < n && !active[node] { node += 1; }
        if node == n { break; }
        active[node] = false;
        while excess[node] > 0 {
            let mut pushed = false;
            for neighbor in 0..n + 2 {
                if excess[node] == 0 { break; }
                let edge = node * AUGMENTED_VERTICES + neighbor;
                if residual[edge] <= 0 || height[node] != height[neighbor] + 1 { continue; }
                let amount = excess[node].min(residual[edge]);
                residual[edge] -= amount;
                residual[neighbor * AUGMENTED_VERTICES + node] += amount;
                excess[node] -= amount;
                let previous_excess = excess[neighbor];
                excess[neighbor] += amount;
                if neighbor < n && previous_excess == 0 { active[neighbor] = true; }
                pushed = true;
            }
            if excess[node] > 0 && !pushed {
                let mut minimum_height = 1000i32;
                for neighbor in 0..n + 2 {
                    if residual[node * AUGMENTED_VERTICES + neighbor] > 0 {
                        minimum_height = minimum_height.min(height[neighbor]);
                    }
                }
                if minimum_height == 1000 { return -1; }
                height[node] = minimum_height + 1;
            }
        }
    }
    excess[super_sink]
}
