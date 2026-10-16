/// Edmonds–Karp maximum flow over a bounded integral capacity matrix.
const MAX_VERTICES: usize = 16;
const MAX_CAPACITY: i64 = 1_000_000;

#[no_mangle]
pub extern "C" fn edmonds_karp(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 { return -1; }
    let n64 = unsafe { *input };
    let source64 = unsafe { *input.add(1) };
    let sink64 = unsafe { *input.add(2) };
    if n64 < 1 || n64 > MAX_VERTICES as i64 || source64 < 0 || source64 >= n64 ||
        sink64 < 0 || sink64 >= n64 { return -1; }
    let n = n64 as usize;
    if length != 3 + n * n { return -1; }

    let mut residual = [0i64; MAX_VERTICES * MAX_VERTICES];
    for row in 0..n {
        for column in 0..n {
            let capacity = unsafe { *input.add(3 + row * n + column) };
            if capacity < 0 || capacity > MAX_CAPACITY || (row == column && capacity != 0) { return -1; }
            residual[row * n + column] = capacity;
        }
    }
    for left in 0..n {
        for right in left + 1..n {
            if residual[left * n + right] > 0 && residual[right * n + left] > 0 { return -1; }
        }
    }

    let source = source64 as usize;
    let sink = sink64 as usize;
    if source == sink { return 0; }
    let mut total_flow = 0i64;
    loop {
        let mut parent = [-1i32; MAX_VERTICES];
        let mut queue = [0usize; MAX_VERTICES];
        parent[source] = source as i32;
        let (mut head, mut tail) = (0usize, 1usize);
        queue[0] = source;
        while head < tail && parent[sink] == -1 {
            let node = queue[head];
            head += 1;
            for neighbor in 0..n {
                if residual[node * n + neighbor] <= 0 || parent[neighbor] != -1 { continue; }
                parent[neighbor] = node as i32;
                if neighbor == sink { break; }
                queue[tail] = neighbor;
                tail += 1;
            }
        }
        if parent[sink] == -1 { return total_flow; }
        let mut path_flow = MAX_CAPACITY;
        let mut node = sink;
        while node != source {
            let previous = parent[node] as usize;
            path_flow = path_flow.min(residual[previous * n + node]);
            node = previous;
        }
        node = sink;
        while node != source {
            let previous = parent[node] as usize;
            residual[previous * n + node] -= path_flow;
            residual[node * n + previous] += path_flow;
            node = previous;
        }
        total_flow += path_flow;
    }
}
