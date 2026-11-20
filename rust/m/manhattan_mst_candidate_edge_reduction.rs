const MAX_N: usize = 31;
const MAX_INPUT_LENGTH: usize = 1 + 2 * MAX_N;
const MAX_CANDIDATE_EDGES: usize = 4 * MAX_N;
const COORDINATE_LIMIT: i64 = 1_000;
const COORDINATE_BITSET_WORDS: usize = (2 * COORDINATE_LIMIT as usize + 1 + 63) / 64;

#[derive(Clone, Copy, Default)]
struct Point {
    x: i64,
    y: i64,
}

#[derive(Clone, Copy, Default)]
struct Edge {
    weight: i64,
    u: usize,
    v: usize,
}

fn mark_coordinate(seen: &mut [u64; COORDINATE_BITSET_WORDS], coordinate: i64) -> bool {
    let index = (coordinate + COORDINATE_LIMIT) as usize;
    let word = index / 64;
    let bit = 1u64 << (index % 64);
    if seen[word] & bit != 0 {
        return false;
    }
    seen[word] |= bit;
    true
}

fn fenwick_add(tree: &mut [i32; MAX_N + 1], mut index: usize, delta: i32, count: usize) {
    while index <= count {
        tree[index] += delta;
        index += index & index.wrapping_neg();
    }
}

fn fenwick_prefix(tree: &[i32; MAX_N + 1], mut index: usize) -> usize {
    let mut total = 0usize;
    while index > 0 {
        total += tree[index] as usize;
        index &= index - 1;
    }
    total
}

fn fenwick_find_by_order(tree: &[i32; MAX_N + 1], count: usize, order: usize) -> usize {
    let mut step = 1usize;
    while step * 2 <= count {
        step *= 2;
    }
    let mut index = 0usize;
    let mut remaining = order as i32;
    while step > 0 {
        let next = index + step;
        if next <= count && tree[next] < remaining {
            index = next;
            remaining -= tree[next];
        }
        step /= 2;
    }
    index
}

fn find_root(parent: &mut [usize; MAX_N], mut node: usize) -> usize {
    let mut root = node;
    while parent[root] != root {
        root = parent[root];
    }
    while parent[node] != node {
        let next = parent[node];
        parent[node] = root;
        node = next;
    }
    root
}

fn execute(words: &[i64]) -> i64 {
    if words.is_empty() || words.len() > MAX_INPUT_LENGTH {
        return -1;
    }
    let count_value = words[0];
    if !(0..=MAX_N as i64).contains(&count_value) {
        return -1;
    }
    let count = count_value as usize;
    if words.len() != 1 + 2 * count {
        return -1;
    }

    let mut points = [Point::default(); MAX_N];
    let mut seen_x = [0u64; COORDINATE_BITSET_WORDS];
    let mut seen_y = [0u64; COORDINATE_BITSET_WORDS];
    for point in 0..count {
        let x = words[1 + 2 * point];
        let y = words[2 + 2 * point];
        if !(-COORDINATE_LIMIT..=COORDINATE_LIMIT).contains(&x)
            || !(-COORDINATE_LIMIT..=COORDINATE_LIMIT).contains(&y)
        {
            return -1;
        }
        if !mark_coordinate(&mut seen_x, x) || !mark_coordinate(&mut seen_y, y) {
            return -1;
        }
        points[point] = Point { x, y };
    }
    if count < 2 {
        return 0;
    }

    let mut edges = [Edge::default(); MAX_CANDIDATE_EDGES];
    let mut edge_count = 0usize;
    for pass in 0..4 {
        let mut sum_order = [0usize; MAX_N];
        let mut x_order = [0usize; MAX_N];
        for point in 0..count {
            sum_order[point] = point;
            x_order[point] = point;
        }
        sum_order[..count].sort_unstable_by_key(|&point| {
            (points[point].x + points[point].y, points[point].x, point)
        });
        x_order[..count].sort_unstable_by_key(|&point| (points[point].x, point));
        let mut rank_of_id = [0usize; MAX_N];
        let mut id_at_rank = [0usize; MAX_N];
        for rank in 0..count {
            let point = x_order[rank];
            rank_of_id[point] = rank;
            id_at_rank[rank] = point;
        }

        let mut fenwick = [0i32; MAX_N + 1];
        for &current in &sum_order[..count] {
            let current_rank = rank_of_id[current];
            loop {
                let active_count = fenwick_prefix(&fenwick, current_rank + 1);
                if active_count == 0 {
                    break;
                }
                let candidate_rank = fenwick_find_by_order(&fenwick, count, active_count);
                let candidate = id_at_rank[candidate_rank];
                if points[current].x - points[current].y > points[candidate].x - points[candidate].y {
                    break;
                }
                if edge_count >= MAX_CANDIDATE_EDGES {
                    return -1;
                }
                let (u, v) = if current < candidate { (current, candidate) } else { (candidate, current) };
                let weight = (points[current].x - points[candidate].x).abs()
                    + (points[current].y - points[candidate].y).abs();
                edges[edge_count] = Edge { weight, u, v };
                edge_count += 1;
                fenwick_add(&mut fenwick, candidate_rank + 1, -1, count);
            }
            fenwick_add(&mut fenwick, current_rank + 1, 1, count);
        }

        for point in 0..count {
            if pass % 2 == 0 {
                std::mem::swap(&mut points[point].x, &mut points[point].y);
            } else {
                points[point].x = -points[point].x;
            }
        }
    }

    edges[..edge_count].sort_unstable_by_key(|edge| (edge.weight, edge.u, edge.v));
    let mut parent = [0usize; MAX_N];
    let mut size = [1usize; MAX_N];
    for point in 0..count {
        parent[point] = point;
    }
    let mut total = 0i64;
    let mut accepted = 0usize;
    for edge in &edges[..edge_count] {
        let left = find_root(&mut parent, edge.u);
        let right = find_root(&mut parent, edge.v);
        if left == right {
            continue;
        }
        if size[left] < size[right] {
            parent[left] = right;
            size[right] += size[left];
        } else {
            parent[right] = left;
            size[left] += size[right];
        }
        total += edge.weight;
        accepted += 1;
        if accepted + 1 == count {
            break;
        }
    }
    if accepted + 1 != count {
        return -1;
    }
    total
}

#[no_mangle]
pub unsafe extern "C" fn manhattan_mst_candidate_edge_reduction(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length == 0 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    execute(std::slice::from_raw_parts(input, length))
}
