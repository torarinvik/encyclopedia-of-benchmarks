// Clean-room bounded GAPBS Afforest profile; see package LICENSE.txt.
const MAX_N: usize = 16;
const MAX_M: usize = 64;
const MAX_SAMPLES: usize = 64;
const MAX_INPUT: usize = 3 + MAX_SAMPLES + 2 * MAX_M;

fn link_components(u: usize, v: usize, component: &mut [usize; MAX_N]) {
    let mut p1 = component[u];
    let mut p2 = component[v];
    while p1 != p2 {
        let high = p1.max(p2);
        let low = p1.min(p2);
        let parent_high = component[high];
        if parent_high == low { break; }
        if parent_high == high { component[high] = low; break; }
        p1 = component[component[high]];
        p2 = component[low];
    }
}

fn compress_components(n: usize, component: &mut [usize; MAX_N]) {
    for vertex in 0..n {
        while component[vertex] != component[component[vertex]] {
            component[vertex] = component[component[vertex]];
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn gapbs_afforest_components(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT { return -1; }
    let n64 = *input;
    let m64 = *input.add(1);
    let sample_count64 = *input.add(2);
    if !(1..=MAX_N as i64).contains(&n64) || !(0..=MAX_M as i64).contains(&m64)
        || !(1..=MAX_SAMPLES as i64).contains(&sample_count64) { return -1; }
    let n = n64 as usize;
    let m = m64 as usize;
    let sample_count = sample_count64 as usize;
    if length != 3 + sample_count + 2 * m { return -1; }
    let mut samples = [0usize; MAX_SAMPLES];
    for i in 0..sample_count {
        let sample = *input.add(3 + i);
        if sample < 0 || sample >= n64 { return -1; }
        samples[i] = sample as usize;
    }
    let mut adjacency = [[false; MAX_N]; MAX_N];
    for edge in 0..m {
        let pos = 3 + sample_count + 2 * edge;
        let u = *input.add(pos);
        let v = *input.add(pos + 1);
        if u < 0 || v <= u || v >= n64 || adjacency[u as usize][v as usize] { return -1; }
        adjacency[u as usize][v as usize] = true;
        adjacency[v as usize][u as usize] = true;
    }
    let output_bytes = 8 * n;
    if output.is_null() || capacity < output_bytes { return -2; }

    let mut neighbors = [[0usize; MAX_N]; MAX_N];
    let mut degree = [0usize; MAX_N];
    for u in 0..n {
        for v in 0..n {
            if adjacency[u][v] { neighbors[u][degree[u]] = v; degree[u] += 1; }
        }
    }
    let mut component = [0usize; MAX_N];
    for vertex in 0..n { component[vertex] = vertex; }
    for round in 0..2 {
        for u in 0..n {
            if degree[u] > round { link_components(u, neighbors[u][round], &mut component); }
        }
        compress_components(n, &mut component);
    }
    let mut sample_counts = [0usize; MAX_N];
    for &sample in samples[..sample_count].iter() { sample_counts[component[sample]] += 1; }
    let mut skip_label = 0usize;
    for label in 1..n {
        if sample_counts[label] > sample_counts[skip_label] { skip_label = label; }
    }
    let mut skip_is_safe = true;
    for u in 0..n {
        if component[u] != skip_label { continue; }
        for offset in 2..degree[u] {
            if component[neighbors[u][offset]] != skip_label { skip_is_safe = false; break; }
        }
    }
    for u in 0..n {
        if skip_is_safe && component[u] == skip_label { continue; }
        for offset in 2..degree[u] { link_components(u, neighbors[u][offset], &mut component); }
    }
    compress_components(n, &mut component);
    for vertex in 0..n {
        let bits = component[vertex] as u64;
        for byte in 0..8 { *output.add(8 * vertex + byte) = (bits >> (8 * byte)) as u8; }
    }
    output_bytes as i64
}
