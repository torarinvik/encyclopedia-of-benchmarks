const MAX_N: usize = 16;
const MAX_INPUT_VALUES: usize = 257;
const MAX_WEIGHT: i64 = 1_000_000;

/// Return the global minimum cut of a bounded undirected weighted graph.
#[no_mangle]
pub unsafe extern "C" fn stoer_wagner(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_VALUES {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let n_value = values[0];
    if !(2..=MAX_N as i64).contains(&n_value) {
        return -1;
    }
    let n = n_value as usize;
    if length != 1 + n * n {
        return -1;
    }

    let mut graph = [[0i64; MAX_N]; MAX_N];
    for row in 0..n {
        for column in 0..n {
            let weight = values[1 + row * n + column];
            if !(0..=MAX_WEIGHT).contains(&weight) {
                return -1;
            }
            graph[row][column] = weight;
        }
    }
    for row in 0..n {
        if graph[row][row] != 0 {
            return -1;
        }
        for column in row + 1..n {
            if graph[row][column] != graph[column][row] {
                return -1;
            }
        }
    }

    let mut merged = [false; MAX_N];
    let mut min_cut = 120_000_001i64;
    for phase in 0..(n - 1) {
        let mut in_set = [false; MAX_N];
        let mut weights = [0i64; MAX_N];
        let mut previous: Option<usize> = None;
        let mut last: Option<usize> = None;
        for _ in 0..n - phase {
            let mut current: Option<usize> = None;
            let mut max_weight = -1i64;
            for vertex in 0..n {
                if !merged[vertex] && !in_set[vertex] && weights[vertex] > max_weight {
                    max_weight = weights[vertex];
                    current = Some(vertex);
                }
            }
            let Some(current_vertex) = current else { break };
            in_set[current_vertex] = true;
            previous = last;
            last = Some(current_vertex);
            for vertex in 0..n {
                if !merged[vertex] && !in_set[vertex] {
                    weights[vertex] += graph[current_vertex][vertex];
                }
            }
        }
        let Some(last_vertex) = last else { return -1 };
        let Some(previous_vertex) = previous else { return -1 };
        if weights[last_vertex] < min_cut {
            min_cut = weights[last_vertex];
        }
        for vertex in 0..n {
            graph[previous_vertex][vertex] += graph[last_vertex][vertex];
            graph[vertex][previous_vertex] = graph[previous_vertex][vertex];
        }
        merged[last_vertex] = true;
    }
    min_cut
}
