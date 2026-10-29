const MAX_VERTICES: usize = 16;
const MAX_EDGES: usize = 64;
const MAX_INPUT_LENGTH: usize = 3 + 3 * MAX_EDGES;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = (bits >> (byte * 8)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn d_esopo_pape(
    values: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if values.is_null() || length < 3 || length > MAX_INPUT_LENGTH { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let (raw_n, raw_m, raw_source) = (input[0], input[1], input[2]);
    if raw_n < 1 || raw_n > MAX_VERTICES as i64 || raw_m < 0 || raw_m > MAX_EDGES as i64
        || raw_source < 0 || raw_source >= raw_n || length != 3 + 3 * raw_m as usize {
        return -1;
    }
    let (n, m) = (raw_n as usize, raw_m as usize);
    let mut head = [-1i32; MAX_VERTICES];
    let mut to = [0i32; MAX_EDGES];
    let mut next = [-1i32; MAX_EDGES];
    let mut weight = [0i64; MAX_EDGES];
    for edge in 0..m {
        let (u, v, w) = (input[3 + 3 * edge], input[4 + 3 * edge], input[5 + 3 * edge]);
        if u < 0 || u >= raw_n || v < 0 || v >= raw_n || w < 0 || w > 1000 { return -1; }
        to[edge] = v as i32;
        weight[edge] = w;
        next[edge] = head[u as usize];
        head[u as usize] = edge as i32;
    }

    let mut distance = [0i64; MAX_VERTICES];
    let mut reachable = [false; MAX_VERTICES];
    let mut queued = [false; MAX_VERTICES];
    let mut removed_before = [false; MAX_VERTICES];
    let mut deque = [0usize; MAX_VERTICES];
    let (mut front, mut size) = (0usize, 1usize);
    let source = raw_source as usize;
    deque[0] = source;
    distance[source] = 0;
    reachable[source] = true;
    queued[source] = true;
    while size != 0 {
        let vertex = deque[front];
        front = (front + 1) % n;
        size -= 1;
        queued[vertex] = false;
        removed_before[vertex] = true;
        let mut edge = head[vertex];
        while edge != -1 {
            let ei = edge as usize;
            let neighbor = to[ei] as usize;
            let candidate = distance[vertex] + weight[ei];
            if !reachable[neighbor] || candidate < distance[neighbor] {
                distance[neighbor] = candidate;
                reachable[neighbor] = true;
                if !queued[neighbor] {
                    if removed_before[neighbor] {
                        front = (front + n - 1) % n;
                        deque[front] = neighbor;
                    } else {
                        deque[(front + size) % n] = neighbor;
                    }
                    size += 1;
                    queued[neighbor] = true;
                }
            }
            edge = next[ei];
        }
    }

    let byte_count = 8 * n;
    if output.is_null() || capacity < byte_count { return -2; }
    for vertex in 0..n {
        store_i64_le(output, 8 * vertex, if reachable[vertex] { distance[vertex] } else { -1 });
    }
    byte_count as i64
}
