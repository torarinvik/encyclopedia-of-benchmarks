const MAX_N: usize = 8;
const MAX_INPUT_LENGTH: usize = 59;

#[no_mangle]
pub unsafe extern "C" fn reverse_cuthill_mckee(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let n64 = *input;
    let m64 = *input.add(1);
    if !(1..=MAX_N as i64).contains(&n64)
        || m64 < 0
        || m64 > n64 * (n64 - 1) / 2
        || length != 2 + 2 * m64 as usize
    {
        return -1;
    }
    let n = n64 as usize;
    let m = m64 as usize;

    let mut adjacency = [[false; MAX_N]; MAX_N];
    for edge in 0..m {
        let u64 = *input.add(2 + 2 * edge);
        let v64 = *input.add(3 + 2 * edge);
        if u64 < 0 || u64 >= n64 || v64 < 0 || v64 >= n64 || u64 == v64 {
            return -1;
        }
        let u = u64 as usize;
        let v = v64 as usize;
        if adjacency[u][v] {
            return -1;
        }
        adjacency[u][v] = true;
        adjacency[v][u] = true;
    }

    let mut degree = [0usize; MAX_N];
    for u in 0..n {
        for v in 0..n {
            if adjacency[u][v] {
                degree[u] += 1;
            }
        }
    }

    let mut visited = [false; MAX_N];
    let mut queue = [0usize; MAX_N];
    let mut cm_order = [0usize; MAX_N];
    let mut order_count = 0usize;
    while order_count < n {
        let mut root = None;
        for vertex in 0..n {
            if !visited[vertex]
                && root.map_or(true, |best: usize| {
                    degree[vertex] < degree[best]
                        || (degree[vertex] == degree[best] && vertex < best)
                })
            {
                root = Some(vertex);
            }
        }
        let Some(root) = root else {
            return -1;
        };

        let mut head = 0usize;
        let mut tail = 1usize;
        queue[0] = root;
        visited[root] = true;
        while head < tail {
            let current = queue[head];
            head += 1;
            cm_order[order_count] = current;
            order_count += 1;

            let mut neighbors = [0usize; MAX_N];
            let mut neighbor_count = 0usize;
            for vertex in 0..n {
                if adjacency[current][vertex] && !visited[vertex] {
                    neighbors[neighbor_count] = vertex;
                    neighbor_count += 1;
                }
            }
            for i in 1..neighbor_count {
                let key = neighbors[i];
                let mut j = i;
                while j > 0
                    && (degree[neighbors[j - 1]] > degree[key]
                        || (degree[neighbors[j - 1]] == degree[key]
                            && neighbors[j - 1] > key))
                {
                    neighbors[j] = neighbors[j - 1];
                    j -= 1;
                }
                neighbors[j] = key;
            }
            for &next in neighbors[..neighbor_count].iter() {
                if !visited[next] {
                    visited[next] = true;
                    queue[tail] = next;
                    tail += 1;
                }
            }
        }
    }

    let mut rank = [0usize; MAX_N];
    for i in 0..n {
        rank[cm_order[n - 1 - i]] = i;
    }
    let mut bandwidth = 0usize;
    for u in 0..n {
        for v in (u + 1)..n {
            if adjacency[u][v] {
                bandwidth = bandwidth.max(rank[u].abs_diff(rank[v]));
            }
        }
    }
    let mut rank_word = 0i64;
    for i in 0..n {
        rank_word |= (cm_order[n - 1 - i] as i64) << (3 * i);
    }
    ((bandwidth as i64) << 24) | rank_word
}
