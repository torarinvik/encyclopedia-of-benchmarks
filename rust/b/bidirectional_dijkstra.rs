const MAX_VERTICES: usize = 64;
const MAX_EDGES: usize = 256;
const MAX_WEIGHT: i64 = 1_000_000;
const INF: i64 = 1_000_000_000;

#[no_mangle]
pub unsafe extern "C" fn bidirectional_dijkstra(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 4 {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let nv = values[0];
    let mv = values[1];
    let source_v = values[2];
    let target_v = values[3];
    if nv < 1 || nv > MAX_VERTICES as i64 || mv < 0 || mv > MAX_EDGES as i64 {
        return -1;
    }
    if source_v < 0 || source_v >= nv || target_v < 0 || target_v >= nv {
        return -1;
    }
    let n = nv as usize;
    let m = mv as usize;
    if length != 4 + 3 * m {
        return -1;
    }
    for edge in 0..m {
        let from = values[4 + 3 * edge];
        let to = values[5 + 3 * edge];
        let weight = values[6 + 3 * edge];
        if from < 0 || from >= nv || to < 0 || to >= nv || weight < 0 || weight > MAX_WEIGHT {
            return -1;
        }
    }
    let source = source_v as usize;
    let target = target_v as usize;
    if source == target {
        return 0;
    }

    let mut forward = [INF; MAX_VERTICES];
    let mut backward = [INF; MAX_VERTICES];
    let mut settled_forward = [false; MAX_VERTICES];
    let mut settled_backward = [false; MAX_VERTICES];
    forward[source] = 0;
    backward[target] = 0;
    let mut best = INF;

    for _ in 0..(2 * n) {
        let mut next_forward = n;
        let mut next_backward = n;
        let mut min_forward = INF;
        let mut min_backward = INF;
        for vertex in 0..n {
            if !settled_forward[vertex] && forward[vertex] < min_forward {
                min_forward = forward[vertex];
                next_forward = vertex;
            }
            if !settled_backward[vertex] && backward[vertex] < min_backward {
                min_backward = backward[vertex];
                next_backward = vertex;
            }
        }
        if next_forward == n || next_backward == n {
            break;
        }
        if best != INF && min_forward + min_backward >= best {
            break;
        }

        if min_forward <= min_backward {
            let current = next_forward;
            settled_forward[current] = true;
            if backward[current] != INF {
                best = best.min(forward[current] + backward[current]);
            }
            for edge in 0..m {
                if values[4 + 3 * edge] as usize != current {
                    continue;
                }
                let to = values[5 + 3 * edge] as usize;
                let candidate = forward[current] + values[6 + 3 * edge];
                if !settled_forward[to] && candidate < forward[to] {
                    forward[to] = candidate;
                }
                if backward[to] != INF {
                    best = best.min(candidate + backward[to]);
                }
            }
        } else {
            let current = next_backward;
            settled_backward[current] = true;
            if forward[current] != INF {
                best = best.min(forward[current] + backward[current]);
            }
            for edge in 0..m {
                if values[5 + 3 * edge] as usize != current {
                    continue;
                }
                let from = values[4 + 3 * edge] as usize;
                let candidate = backward[current] + values[6 + 3 * edge];
                if !settled_backward[from] && candidate < backward[from] {
                    backward[from] = candidate;
                }
                if forward[from] != INF {
                    best = best.min(forward[from] + values[6 + 3 * edge] + backward[current]);
                }
            }
        }
    }
    if best == INF { -1 } else { best }
}
