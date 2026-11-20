// Clean-room LDFS+ / Rightmost-Neighbor path-cover profile.
use core::cmp::Ordering;
use core::slice;

const MAX_N: usize = 8;
const MAX_PARSEABLE: usize = 18;

#[no_mangle]
pub unsafe extern "C" fn cocomparability_ldfs_minimum_path_cover(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || length == 0 || length > MAX_PARSEABLE {
        return -1;
    }
    let n_value = *input;
    if !(1..=MAX_N as i64).contains(&n_value) || length != 1 + 2 * n_value as usize {
        return -1;
    }
    let n = n_value as usize;
    let values = slice::from_raw_parts(input, length);
    let full = (1u16 << n) - 1;
    let mut adjacency = [0u16; MAX_N];
    for v in 0..n {
        let row = values[1 + v];
        if row < 0 || row > full as i64 || row & (1i64 << v) != 0 {
            return -1;
        }
        adjacency[v] = row as u16;
    }
    for u in 0..n {
        for v in 0..n {
            if ((adjacency[u] >> v) & 1) != ((adjacency[v] >> u) & 1) {
                return -1;
            }
        }
    }
    let mut order = [0usize; MAX_N];
    let mut rank = [0usize; MAX_N];
    let mut seen_order = [false; MAX_N];
    for i in 0..n {
        let value = values[1 + n + i];
        if value < 0 || value >= n as i64 || seen_order[value as usize] {
            return -1;
        }
        order[i] = value as usize;
        rank[value as usize] = i;
        seen_order[value as usize] = true;
    }
    for i in 0..n {
        for j in i + 1..n {
            for k in j + 1..n {
                let a = order[i];
                let b = order[j];
                let c = order[k];
                if (adjacency[a] >> c) & 1 != 0
                    && (adjacency[a] >> b) & 1 == 0
                    && (adjacency[b] >> c) & 1 == 0
                {
                    return -1;
                }
            }
        }
    }
    let mut reached = 1u16;
    let mut queue = [0usize; MAX_N];
    let mut head = 0;
    let mut tail = 1;
    queue[0] = 0;
    while head < tail {
        let u = queue[head];
        head += 1;
        for v in 0..n {
            let bit = 1u16 << v;
            if adjacency[u] & bit != 0 && reached & bit == 0 {
                reached |= bit;
                queue[tail] = v;
                tail += 1;
            }
        }
    }
    if reached != full {
        return -1;
    }

    let mut labels = [[0u8; MAX_N]; MAX_N];
    let mut label_len = [0usize; MAX_N];
    let mut visited = [false; MAX_N];
    let mut ldfs = [0usize; MAX_N];
    for step in 1..=n {
        let mut chosen = usize::MAX;
        for v in 0..n {
            if visited[v] {
                continue;
            }
            if chosen == usize::MAX {
                chosen = v;
                continue;
            }
            let cmp = labels[v][..label_len[v]].cmp(&labels[chosen][..label_len[chosen]]);
            if cmp == Ordering::Greater || (cmp == Ordering::Equal && rank[v] > rank[chosen]) {
                chosen = v;
            }
        }
        ldfs[step - 1] = chosen;
        visited[chosen] = true;
        for v in 0..n {
            if !visited[v] && adjacency[chosen] & (1u16 << v) != 0 {
                for i in (1..=label_len[v]).rev() {
                    labels[v][i] = labels[v][i - 1];
                }
                labels[v][0] = step as u8;
                label_len[v] += 1;
            }
        }
    }
    let mut position = [0usize; MAX_N];
    for i in 0..n {
        position[ldfs[i]] = i;
    }

    visited.fill(false);
    let mut paths = 0i64;
    loop {
        let mut current = usize::MAX;
        for v in 0..n {
            if !visited[v] && (current == usize::MAX || position[v] > position[current]) {
                current = v;
            }
        }
        if current == usize::MAX {
            break;
        }
        paths += 1;
        visited[current] = true;
        loop {
            let mut next = usize::MAX;
            for v in 0..n {
                if !visited[v]
                    && adjacency[current] & (1u16 << v) != 0
                    && (next == usize::MAX || position[v] > position[next])
                {
                    next = v;
                }
            }
            if next == usize::MAX {
                break;
            }
            visited[next] = true;
            current = next;
        }
    }
    paths
}
