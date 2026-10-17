/// Bounded Johnson all-pairs distances for the pinned Java matrix contract.
const MAX_VERTICES: usize = 16;
const MAX_INPUT_LENGTH: usize = 1 + MAX_VERTICES * MAX_VERTICES;
const MAX_WEIGHT: i64 = 32;
const UNREACHABLE_SENTINEL: i64 = 1i64 << 62;
const FNV_OFFSET_BASIS: u64 = 14695981039346656037;
const FNV_PRIME: u64 = 1099511628211;

fn fnv_word(mut hash: u64, value: i64) -> u64 {
    let bits = value as u64;
    for byte in 0..8 {
        hash ^= (bits >> (8 * byte)) & 0xff;
        hash = hash.wrapping_mul(FNV_PRIME);
    }
    hash
}

#[no_mangle]
pub unsafe extern "C" fn johnsons_algorithm(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let input = std::slice::from_raw_parts(input, length);
    let vertex_value = input[0];
    if !(1..=MAX_VERTICES as i64).contains(&vertex_value) {
        return -1;
    }
    let vertices = vertex_value as usize;
    if length != 1 + vertices * vertices {
        return -1;
    }

    let mut weight = [[0i64; MAX_VERTICES]; MAX_VERTICES];
    let mut edge = [[false; MAX_VERTICES]; MAX_VERTICES];
    let mut reachable = [[false; MAX_VERTICES]; MAX_VERTICES];
    for from in 0..vertices {
        reachable[from][from] = true;
        for to in 0..vertices {
            let value = input[1 + from * vertices + to];
            if !(-MAX_WEIGHT..=MAX_WEIGHT).contains(&value) {
                return -1;
            }
            if from != to && value != 0 {
                edge[from][to] = true;
                weight[from][to] = value;
                reachable[from][to] = true;
            }
        }
    }
    for intermediate in 0..vertices {
        for from in 0..vertices {
            for to in 0..vertices {
                reachable[from][to] |= reachable[from][intermediate] && reachable[intermediate][to];
            }
        }
    }
    for from in 0..vertices {
        for to in 0..vertices {
            if !reachable[from][to] {
                return -1;
            }
        }
    }

    let mut potential = [0i64; MAX_VERTICES];
    for _ in 1..vertices {
        let mut updated = false;
        for from in 0..vertices {
            for to in 0..vertices {
                if !edge[from][to] {
                    continue;
                }
                let candidate = potential[from] + weight[from][to];
                if candidate < potential[to] {
                    potential[to] = candidate;
                    updated = true;
                }
            }
        }
        if !updated {
            break;
        }
    }
    for from in 0..vertices {
        for to in 0..vertices {
            if !edge[from][to] {
                continue;
            }
            if potential[from] + weight[from][to] < potential[to]
                || weight[from][to] + potential[from] - potential[to] <= 0
            {
                return -1;
            }
        }
    }

    let mut reweighted = [[0i64; MAX_VERTICES]; MAX_VERTICES];
    for from in 0..vertices {
        for to in 0..vertices {
            if edge[from][to] {
                reweighted[from][to] = weight[from][to] + potential[from] - potential[to];
            }
        }
    }

    let mut result = FNV_OFFSET_BASIS;
    for source in 0..vertices {
        let mut distance = [i64::MAX; MAX_VERTICES];
        let mut visited = [false; MAX_VERTICES];
        distance[source] = 0;
        for _ in 0..vertices {
            let mut current = vertices;
            for vertex in 0..vertices {
                if !visited[vertex] && (current == vertices || distance[vertex] <= distance[current]) {
                    current = vertex;
                }
            }
            if current == vertices || distance[current] == i64::MAX {
                break;
            }
            visited[current] = true;
            for next in 0..vertices {
                if !edge[current][next] || visited[next] {
                    continue;
                }
                let candidate = distance[current] + reweighted[current][next];
                if candidate < distance[next] {
                    distance[next] = candidate;
                }
            }
        }
        for destination in 0..vertices {
            let output = if distance[destination] == i64::MAX {
                UNREACHABLE_SENTINEL
            } else {
                distance[destination] - potential[source] + potential[destination]
            };
            result = fnv_word(result, output);
        }
    }
    (result & i64::MAX as u64) as i64
}
