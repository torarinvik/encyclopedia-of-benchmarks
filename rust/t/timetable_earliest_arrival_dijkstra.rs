const MAX_N: usize = 8;
const MAX_ARCS: usize = 12;
const MAX_TRIPS: usize = 4;
const INF: i64 = i64::MAX / 4;
const MAX_OUTPUT_BYTES: usize = 88;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn timetable_earliest_arrival_dijkstra(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 5 || length > 138 { return -1; }
    let n_raw = *input;
    let arcs_raw = *input.add(1);
    let source_raw = *input.add(2);
    let target_raw = *input.add(3);
    let start_time = *input.add(4);
    if n_raw < 2 || n_raw > MAX_N as i64 || arcs_raw < 0 || arcs_raw > MAX_ARCS as i64 ||
            source_raw < 0 || source_raw >= n_raw || target_raw < 0 || target_raw >= n_raw ||
            start_time < 0 || start_time > 1000 { return -1; }
    let n = n_raw as usize;
    let arc_count = arcs_raw as usize;
    let source = source_raw as usize;
    let target = target_raw as usize;
    let mut arc_u = [0usize; MAX_ARCS];
    let mut arc_v = [0usize; MAX_ARCS];
    let mut trip_count = [0usize; MAX_ARCS];
    let mut departure = [[0i64; MAX_TRIPS]; MAX_ARCS];
    let mut arrival = [[0i64; MAX_TRIPS]; MAX_ARCS];
    let mut cursor = 5usize;
    for edge in 0..arc_count {
        if cursor + 3 > length { return -1; }
        let u_raw = *input.add(cursor); let v_raw = *input.add(cursor + 1); let count_raw = *input.add(cursor + 2);
        cursor += 3;
        if u_raw < 0 || u_raw >= n_raw || v_raw < 0 || v_raw >= n_raw || u_raw == v_raw ||
                count_raw < 1 || count_raw > MAX_TRIPS as i64 || cursor + 2 * count_raw as usize > length { return -1; }
        let u = u_raw as usize; let v = v_raw as usize; let count = count_raw as usize;
        for prior in 0..edge { if arc_u[prior] == u && arc_v[prior] == v { return -1; } }
        arc_u[edge] = u; arc_v[edge] = v; trip_count[edge] = count;
        for trip in 0..count {
            let dep = *input.add(cursor); let arr = *input.add(cursor + 1); cursor += 2;
            if dep < 0 || dep > 1000 || arr <= dep || arr > 2000 ||
                    (trip > 0 && (dep <= departure[edge][trip - 1] || arr < arrival[edge][trip - 1])) { return -1; }
            departure[edge][trip] = dep; arrival[edge][trip] = arr;
        }
    }
    if cursor != length { return -1; }

    let mut distance = [INF; MAX_N];
    let mut parent = [-1i32; MAX_N];
    let mut settled = [false; MAX_N];
    distance[source] = start_time;
    for _ in 0..n {
        let mut chosen: Option<usize> = None;
        for vertex in 0..n {
            if !settled[vertex] && distance[vertex] < INF &&
                    chosen.map_or(true, |best| distance[vertex] < distance[best] ||
                        (distance[vertex] == distance[best] && vertex < best)) { chosen = Some(vertex); }
        }
        let u = match chosen { Some(value) => value, None => break };
        settled[u] = true;
        for edge in 0..arc_count {
            if arc_u[edge] != u || settled[arc_v[edge]] { continue; }
            let mut trip = 0;
            while trip < trip_count[edge] && departure[edge][trip] < distance[u] { trip += 1; }
            if trip == trip_count[edge] { continue; }
            let v = arc_v[edge];
            let candidate = arrival[edge][trip];
            if candidate < distance[v] || (candidate == distance[v] && (parent[v] < 0 || u < parent[v] as usize)) {
                distance[v] = candidate;
                parent[v] = u as i32;
            }
        }
    }

    let mut reverse_path = [0usize; MAX_N];
    let mut path_length = 0usize;
    if distance[target] < INF {
        let mut current = target;
        reverse_path[path_length] = current; path_length += 1;
        while current != source && path_length < n {
            if parent[current] < 0 { path_length = 0; break; }
            current = parent[current] as usize;
            reverse_path[path_length] = current; path_length += 1;
        }
        if path_length == 0 || reverse_path[path_length - 1] != source { path_length = 0; }
    }
    let reachable = path_length > 0;
    let output_bytes = if reachable { 8 * (3 + path_length) } else { 24 };
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut staged = [0u8; MAX_OUTPUT_BYTES];
    store_i64_le(staged.as_mut_ptr(), 0, if reachable { 1 } else { 0 });
    store_i64_le(staged.as_mut_ptr(), 8, if reachable { distance[target] } else { -1 });
    store_i64_le(staged.as_mut_ptr(), 16, path_length as i64);
    if reachable {
        for i in 0..path_length { store_i64_le(staged.as_mut_ptr(), 24 + 8 * i, reverse_path[path_length - 1 - i] as i64); }
    }
    for byte in 0..output_bytes { *output.add(byte) = staged[byte]; }
    output_bytes as i64
}
