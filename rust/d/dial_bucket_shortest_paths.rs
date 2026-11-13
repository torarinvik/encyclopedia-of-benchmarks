const MAX_N: usize = 16;
const MAX_M: usize = 64;
const MAX_DISTANCE: i64 = 120;
const BUCKETS: usize = 9;
const MAX_RECORDS: usize = MAX_M + 1;

fn put_i64_le(output: &mut [u8; 128], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn dial_bucket_shortest_paths(input: *const i64, length: usize,
                                                       output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > 196 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n64 = values[0];
    let m64 = values[1];
    let source64 = values[2];
    if n64 < 1 || n64 > MAX_N as i64 || m64 < 0 || m64 > MAX_M as i64 ||
        source64 < 0 || source64 >= n64 || length != 3 + 3 * m64 as usize { return -1; }
    let n = n64 as usize;
    let m = m64 as usize;
    let source = source64 as usize;
    let mut to = [0usize; MAX_M];
    let mut next = [MAX_M; MAX_M];
    let mut weight = [0i64; MAX_M];
    let mut head = [MAX_M; MAX_N];
    for edge in 0..m {
        let u = values[3 + 3 * edge];
        let v = values[4 + 3 * edge];
        let w = values[5 + 3 * edge];
        if u < 0 || u >= n64 || v < 0 || v >= n64 || w < 0 || w > 8 { return -1; }
        let from = u as usize;
        to[edge] = v as usize;
        weight[edge] = w;
        next[edge] = head[from];
        head[from] = edge;
    }
    let needed = 8 * n;
    if output.is_null() || capacity < needed { return -2; }

    let mut distance = [MAX_DISTANCE + 1; MAX_N];
    let mut settled = [false; MAX_N];
    distance[source] = 0;
    let mut bucket_head = [MAX_RECORDS; BUCKETS];
    let mut bucket_tail = [MAX_RECORDS; BUCKETS];
    let mut record_vertex = [0usize; MAX_RECORDS];
    let mut record_next = [MAX_RECORDS; MAX_RECORDS];
    let mut record_distance = [0i64; MAX_RECORDS];
    let mut used = 1usize;
    record_vertex[0] = source;
    record_distance[0] = 0;
    bucket_head[0] = 0;
    bucket_tail[0] = 0;
    for current in 0..=MAX_DISTANCE {
        let bucket = current as usize % BUCKETS;
        while bucket_head[bucket] != MAX_RECORDS {
            let record = bucket_head[bucket];
            bucket_head[bucket] = record_next[record];
            if bucket_head[bucket] == MAX_RECORDS { bucket_tail[bucket] = MAX_RECORDS; }
            let u = record_vertex[record];
            if record_distance[record] != current || settled[u] || distance[u] != current { continue; }
            settled[u] = true;
            let mut edge = head[u];
            while edge != MAX_M {
                let v = to[edge];
                let candidate = current + weight[edge];
                if !settled[v] && candidate < distance[v] {
                    if used >= MAX_RECORDS { return -1; }
                    distance[v] = candidate;
                    let destination = candidate as usize % BUCKETS;
                    record_vertex[used] = v;
                    record_distance[used] = candidate;
                    record_next[used] = MAX_RECORDS;
                    if bucket_tail[destination] == MAX_RECORDS { bucket_head[destination] = used; }
                    else { record_next[bucket_tail[destination]] = used; }
                    bucket_tail[destination] = used;
                    used += 1;
                }
                edge = next[edge];
            }
        }
    }
    let mut staged = [0u8; 128];
    for vertex in 0..n {
        put_i64_le(&mut staged, 8 * vertex,
            if distance[vertex] > MAX_DISTANCE { -1 } else { distance[vertex] });
    }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, needed);
    needed as i64
}

