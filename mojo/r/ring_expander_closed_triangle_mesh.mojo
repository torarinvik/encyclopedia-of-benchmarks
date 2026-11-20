# Source-faithful seeded Ring-Expander pass on a bounded closed triangle mesh.
const MAX_N: usize = 12
const MAX_T: usize = 20
const MAX_C: usize = 60
const MAX_INPUT: usize = 64

def ring_next(corner: usize) -> usize:
    3 * (corner // 3) + ((corner % 3) + 1) % 3

def ring_prev(corner: usize) -> usize:
    3 * (corner // 3) + ((corner % 3) + 2) % 3

def ring_vertex(faces: view[i64], corner: usize) -> usize:
    faces[3 * (corner // 3) + corner % 3].usize()

def ring_store(output: mutable view[u8], offset: usize, value: i64) -> None:
    bits: u64 = value.u64()
    for byte in 0..<8:
        output[offset + byte] <- (bits & 255).u8()
        bits <- bits >> 8

def ring_run(n: usize, t: usize, seed: usize, faces: view[i64],
             trace: mutable view[i64], trace_count: mutable usize&,
             vertex_mask: mutable u64&, triangle_mask: mutable u64&) -> bool:
    opposite: mutable i32[MAX_C] = zeroed
    link: mutable bool[MAX_N * MAX_N * MAX_N] = zeroed
    used: mutable bool[MAX_N] = zeroed
    edge_count: mutable u8[MAX_N * MAX_N] = zeroed
    edge_first: mutable i32[MAX_N * MAX_N] = zeroed
    edge_second: mutable i32[MAX_N * MAX_N] = zeroed
    for corner in 0..<3 * t:
        opposite[corner] <- -1
    for a in 0..<MAX_N:
        for b in 0..<MAX_N:
            edge_first[a * MAX_N + b] <- -1
            edge_second[a * MAX_N + b] <- -1
    for ti in 0..<t:
        a: usize = faces[3 * ti].usize()
        b: usize = faces[3 * ti + 1].usize()
        c: usize = faces[3 * ti + 2].usize()
        used[a] <- true
        used[b] <- true
        used[c] <- true
        link[a * MAX_N * MAX_N + b * MAX_N + c] <- true
        link[a * MAX_N * MAX_N + c * MAX_N + b] <- true
        link[b * MAX_N * MAX_N + c * MAX_N + a] <- true
        link[b * MAX_N * MAX_N + a * MAX_N + c] <- true
        link[c * MAX_N * MAX_N + a * MAX_N + b] <- true
        link[c * MAX_N * MAX_N + b * MAX_N + a] <- true
        for j in 0..<3:
            first: usize = faces[3 * ti + (j + 1) % 3].usize()
            second: usize = faces[3 * ti + (j + 2) % 3].usize()
            low: usize = first
            high: usize = second
            if low > high:
                low = second
                high = first
            edge_at: usize = low * MAX_N + high
            count: u8 = edge_count[edge_at]
            if count == 0: edge_first[edge_at] <- (3 * ti + j).i32()
            elif count == 1: edge_second[edge_at] <- (3 * ti + j).i32()
            else: return false
            edge_count[edge_at] <- count + 1
    for v in 0..<n:
        if not used[v]: return false

    for low in 0..<n:
        for high in low + 1..<n:
            edge_at: usize = low * MAX_N + high
            if edge_count[edge_at] == 0: continue
            if edge_count[edge_at] != 2: return false
            a: usize = edge_first[edge_at].usize()
            b: usize = edge_second[edge_at].usize()
            at: usize = a // 3
            aj: usize = a % 3
            bt: usize = b // 3
            bj: usize = b % 3
            a0: i64 = faces[3 * at + (aj + 1) % 3]
            a1: i64 = faces[3 * at + (aj + 2) % 3]
            b0: i64 = faces[3 * bt + (bj + 1) % 3]
            b1: i64 = faces[3 * bt + (bj + 2) % 3]
            if a0 != b1 or a1 != b0: return false
            opposite[a] <- b.i32()
            opposite[b] <- a.i32()

    for v in 0..<n:
        start: mutable i64 = -1
        for w in 0..<n:
            degree: mutable usize = 0
            for x in 0..<n:
                if link[v * MAX_N * MAX_N + w * MAX_N + x]: degree <- degree + 1
            if degree > 0 and start < 0: start <- w.i64()
            if degree > 0 and degree != 2: return false
        if start < 0: return false
        seen: mutable bool[MAX_N] = zeroed
        queue: mutable usize[MAX_N] = zeroed
        head: mutable usize = 0
        tail: mutable usize = 0
        seen[start.usize()] <- true
        queue[tail] <- start.usize()
        tail <- tail + 1
        while head < tail:
            w: usize = queue[head]
            head <- head + 1
            for x in 0..<n:
                if link[v * MAX_N * MAX_N + w * MAX_N + x] and not seen[x]:
                    seen[x] <- true
                    queue[tail] <- x
                    tail <- tail + 1
        for w in 0..<n:
            has_edge: mutable bool = false
            for x in 0..<n:
                has_edge = has_edge or link[v * MAX_N * MAX_N + w * MAX_N + x]
            if has_edge and not seen[w]: return false

    reached: mutable bool[MAX_T] = zeroed
    tri_queue: mutable usize[MAX_T] = zeroed
    head: mutable usize = 0
    tail: mutable usize = 0
    reached[0] <- true
    tri_queue[tail] <- 0
    tail <- tail + 1
    while head < tail:
        ti: usize = tri_queue[head]
        head <- head + 1
        for j in 0..<3:
            other: usize = opposite[3 * ti + j].usize() // 3
            if not reached[other]:
                reached[other] <- true
                tri_queue[tail] <- other
                tail <- tail + 1
    for ti in 0..<t:
        if not reached[ti]: return false

    seen_corners: mutable bool[MAX_C] = zeroed
    trace_count <- 0
    vertex_mask <- 0
    triangle_mask <- 0
    vertex_mask <- vertex_mask | ((1).u64() << ring_vertex(faces, ring_next(seed)))
    vertex_mask <- vertex_mask | ((1).u64() << ring_vertex(faces, ring_prev(seed)))
    stop: usize = opposite[seed].usize()
    current: mutable usize = seed
    while current != stop:
        if current >= 3 * t or seen_corners[current] or trace_count >= 3 * t: return false
        seen_corners[current] <- true
        trace[trace_count] <- current.i64()
        trace_count <- trace_count + 1
        ti: usize = current // 3
        v: usize = ring_vertex(faces, current)
        if ((vertex_mask >> v) & 1) == 0:
            vertex_mask <- vertex_mask | ((1).u64() << v)
            triangle_mask <- triangle_mask | ((1).u64() << ti)
        elif ((triangle_mask >> ti) & 1) == 0:
            current <- opposite[current].usize()
        current <- opposite[ring_prev(current)].usize()
    true

def ring_expander_closed_triangle_mesh_impl(input: view[i64], output_ptr: UnsafePointer[UInt8, MutAnyOrigin],
        length: usize, capacity: usize) -> i64:
    if length < 15 or length > MAX_INPUT: return -1
    n_raw: i64 = input[0]
    t_raw: i64 = input[1]
    seed_raw: i64 = input[2]
    if n_raw < 4 or n_raw > MAX_N.i64() or t_raw < 4 or t_raw > MAX_T.i64(): return -1
    n: usize = n_raw.usize()
    t: usize = t_raw.usize()
    if length != 3 + 3 * t or seed_raw < 0 or seed_raw >= (3 * t).i64(): return -1
    seed: usize = seed_raw.usize()
    faces: mutable i64[MAX_C] = zeroed
    for i in 0..<3 * t:
        value: i64 = input[3 + i]
        if value < 0 or value >= n_raw: return -1
        faces[i] <- value
    for ti in 0..<t:
        if faces[3 * ti] == faces[3 * ti + 1] or faces[3 * ti + 1] == faces[3 * ti + 2] or faces[3 * ti + 2] == faces[3 * ti]: return -1
    trace: mutable i64[MAX_C] = zeroed
    trace_count: mutable usize = 0
    vertices: mutable u64 = 0
    triangles: mutable u64 = 0
    if not ring_run(n, t, seed, faces[0:3 * t], trace[0:MAX_C], trace_count, vertices, triangles): return -1
    words: usize = 1 + trace_count + 2
    bytes: usize = 8 * words
    if output_ptr == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < bytes: return -2
    output: mutable view[u8] = output_ptr[0:bytes]
    ring_store(output, 0, trace_count.i64())
    for i in 0..<trace_count:
        ring_store(output, 8 * (i + 1), trace[i])
    ring_store(output, 8 * (trace_count + 1), vertices.i64())
    ring_store(output, 8 * (trace_count + 2), triangles.i64())
    bytes.i64()

@export("ring_expander_closed_triangle_mesh")
fn ring_expander_closed_triangle_mesh(
        input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 15 or length > MAX_INPUT: return -1
    input_view: view[i64] = input[0:length]
    ring_expander_closed_triangle_mesh_impl(input_view, output, length, capacity)
