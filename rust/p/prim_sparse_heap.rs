const MAX_VERTICES: usize = 64;
const MAX_EDGES: usize = 4096;
const MAX_ARCS: usize = 2 * MAX_EDGES;
const NONE: usize = MAX_VERTICES;
const NO_ARC: usize = MAX_ARCS;

fn before(best: &[i64; MAX_VERTICES], left: usize, right: usize) -> bool {
    best[left] < best[right] || (best[left] == best[right] && left < right)
}

fn exchange(heap: &mut [usize; MAX_VERTICES], position: &mut [usize; MAX_VERTICES],
            first: usize, second: usize) {
    heap.swap(first, second);
    position[heap[first]] = first;
    position[heap[second]] = second;
}

fn sift_up(heap: &mut [usize; MAX_VERTICES], position: &mut [usize; MAX_VERTICES],
           best: &[i64; MAX_VERTICES], mut at: usize) {
    while at > 0 {
        let parent = (at - 1) / 2;
        if !before(best, heap[at], heap[parent]) { break; }
        exchange(heap, position, at, parent);
        at = parent;
    }
}

fn pop(heap: &mut [usize; MAX_VERTICES], position: &mut [usize; MAX_VERTICES],
       count: &mut usize, best: &[i64; MAX_VERTICES]) -> usize {
    let result = heap[0];
    position[result] = NONE;
    *count -= 1;
    if *count > 0 {
        heap[0] = heap[*count];
        position[heap[0]] = 0;
        let mut at = 0;
        while 2 * at + 1 < *count {
            let mut child = 2 * at + 1;
            if child + 1 < *count && before(best, heap[child + 1], heap[child]) { child += 1; }
            if !before(best, heap[child], heap[at]) { break; }
            exchange(heap, position, at, child);
            at = child;
        }
    }
    result
}

fn solve(values: &[i64]) -> i64 {
    if values.len() < 2 || values.len() > 2 + 3 * MAX_EDGES { return -2; }
    if values[0] < 0 || values[0] > MAX_VERTICES as i64 || values[1] < 0 || values[1] > MAX_EDGES as i64 { return -2; }
    let vertices = values[0] as usize;
    let edge_count = values[1] as usize;
    if values.len() != 2 + 3 * edge_count || (vertices == 0 && edge_count != 0) { return -2; }
    if vertices == 0 { return 0; }
    for edge in 0..edge_count {
        let origin = values[2 + 3 * edge];
        let destination = values[3 + 3 * edge];
        let weight = values[4 + 3 * edge];
        if origin < 0 || destination < 0 || origin as u64 >= vertices as u64 ||
            destination as u64 >= vertices as u64 || !(0..=2_147_483_647).contains(&weight) { return -2; }
    }

    let mut head = [NO_ARC; MAX_VERTICES];
    let mut next = [NO_ARC; MAX_ARCS];
    let mut to = [0usize; MAX_ARCS];
    let mut arc_weight = [0i64; MAX_ARCS];
    let mut arc_count = 0;
    for edge in 0..edge_count {
        let origin = values[2 + 3 * edge] as usize;
        let destination = values[3 + 3 * edge] as usize;
        let weight = values[4 + 3 * edge];
        if origin == destination { continue; }
        to[arc_count] = destination;
        arc_weight[arc_count] = weight;
        next[arc_count] = head[origin];
        head[origin] = arc_count;
        arc_count += 1;
        to[arc_count] = origin;
        arc_weight[arc_count] = weight;
        next[arc_count] = head[destination];
        head[destination] = arc_count;
        arc_count += 1;
    }

    let mut best = [0i64; MAX_VERTICES];
    let mut has_best = [false; MAX_VERTICES];
    let mut selected = [false; MAX_VERTICES];
    let mut heap = [0usize; MAX_VERTICES];
    let mut position = [NONE; MAX_VERTICES];
    let mut heap_count = 1;
    let mut selected_count = 0;
    let mut total = 0i64;
    heap[0] = 0;
    position[0] = 0;
    has_best[0] = true;

    while heap_count > 0 {
        let origin = pop(&mut heap, &mut position, &mut heap_count, &best);
        selected[origin] = true;
        selected_count += 1;
        total += best[origin];
        let mut arc = head[origin];
        while arc != NO_ARC {
            let destination = to[arc];
            let weight = arc_weight[arc];
            if !selected[destination] && (!has_best[destination] || weight < best[destination]) {
                best[destination] = weight;
                has_best[destination] = true;
                if position[destination] == NONE {
                    heap[heap_count] = destination;
                    position[destination] = heap_count;
                    heap_count += 1;
                }
                let at = position[destination];
                sift_up(&mut heap, &mut position, &best, at);
            }
            arc = next[arc];
        }
    }
    if selected_count == vertices { total } else { -1 }
}

#[no_mangle]
pub extern "C" fn prim_sparse_heap(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > 2 + 3 * MAX_EDGES { return -2; }
    let packed = unsafe { std::slice::from_raw_parts(values, length) };
    solve(packed)
}
