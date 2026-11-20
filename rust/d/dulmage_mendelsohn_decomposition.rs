// Clean-room Dulmage--Mendelsohn decomposition of a bipartite graph.
const SIDE: usize = 6;
const VERTICES: usize = 12;
const EDGES: usize = 36;

fn augment(adjacency: &[u16; SIDE], left: usize, right_count: usize,
           seen: &mut [bool; SIDE], match_right: &mut [i32; SIDE]) -> bool {
    for right in 0..right_count {
        let bit = 1u16 << right;
        if adjacency[left] & bit == 0 || seen[right] { continue; }
        seen[right] = true;
        let mate = match_right[right];
        if mate < 0 || augment(adjacency, mate as usize, right_count, seen, match_right) {
            match_right[right] = left as i32;
            return true;
        }
    }
    false
}

fn maximum_matching(adjacency: &[u16; SIDE], left_count: usize, right_count: usize,
                    match_left: &mut [i32; SIDE], match_right: &mut [i32; SIDE]) -> usize {
    *match_right = [-1; SIDE];
    let mut size = 0;
    for left in 0..left_count {
        let mut seen = [false; SIDE];
        if augment(adjacency, left, right_count, &mut seen, match_right) { size += 1; }
    }
    *match_left = [-1; SIDE];
    for right in 0..right_count {
        if match_right[right] >= 0 { match_left[match_right[right] as usize] = right as i32; }
    }
    size
}

#[no_mangle]
pub unsafe extern "C" fn dulmage_mendelsohn_decomposition(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > 76 { return -1; }
    let left64 = *input;
    let right64 = *input.add(1);
    let edges64 = *input.add(2);
    if left64 < 0 || left64 > SIDE as i64 || right64 < 0 || right64 > SIDE as i64 ||
       left64 + right64 < 1 || edges64 < 0 || edges64 > EDGES as i64 ||
       edges64 > left64 * right64 || length != 3 + 2 * edges64 as usize { return -1; }
    let left_count = left64 as usize;
    let right_count = right64 as usize;
    let total = left_count + right_count;
    let edge_count = edges64 as usize;
    let mut adjacency = [0u16; SIDE];
    let mut global = [0u16; VERTICES];
    for edge in 0..edge_count {
        let u64 = *input.add(3 + 2 * edge);
        let v64 = *input.add(4 + 2 * edge);
        if u64 < 0 || u64 >= left_count as i64 || v64 < 0 || v64 >= right_count as i64 { return -1; }
        let u = u64 as usize;
        let v = v64 as usize;
        let right_vertex = left_count + v;
        let right_bit = 1u16 << v;
        if adjacency[u] & right_bit != 0 { return -1; }
        adjacency[u] |= right_bit;
        global[u] |= 1u16 << right_vertex;
        global[right_vertex] |= 1u16 << u;
    }

    let mut match_left = [-1i32; SIDE];
    let mut match_right = [-1i32; SIDE];
    let matching_size = maximum_matching(&adjacency, left_count, right_count,
                                          &mut match_left, &mut match_right);
    let mut seen = [false; 2 * VERTICES];
    let mut queue = [0usize; 2 * VERTICES];
    let (mut head, mut tail) = (0usize, 0usize);
    for left in 0..left_count {
        if match_left[left] < 0 { let state = 2 * left; seen[state] = true; queue[tail] = state; tail += 1; }
    }
    for right in 0..right_count {
        if match_right[right] < 0 {
            let state = 2 * (left_count + right); seen[state] = true; queue[tail] = state; tail += 1;
        }
    }
    while head < tail {
        let state = queue[head]; head += 1;
        let vertex = state / 2;
        let parity = state & 1;
        for neighbor in 0..total {
            if global[vertex] & (1u16 << neighbor) == 0 { continue; }
            let matched = if vertex < left_count {
                match_left[vertex] == neighbor as i32 - left_count as i32
            } else {
                match_right[vertex - left_count] == neighbor as i32
            };
            if (parity == 0 && matched) || (parity == 1 && !matched) { continue; }
            let next_state = 2 * neighbor + 1 - parity;
            if !seen[next_state] { seen[next_state] = true; queue[tail] = next_state; tail += 1; }
        }
    }

    let mut packed = (matching_size as u64) << 32;
    for vertex in 0..total {
        let code = if seen[2 * vertex] { 0 } else if seen[2 * vertex + 1] { 1 } else { 2 };
        packed |= (code as u64) << (2 * vertex);
    }
    packed as i64
}
