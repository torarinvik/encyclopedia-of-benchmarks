# Bounded recursive FMT profile; all internal graph state uses fixed arrays/views.
const N: usize = 8
const M: usize = 28
const MAX_INPUT: usize = 59

def fmt_store(output: mutable view[u8], offset: usize, value: i64) -> None:
    bits: u64 = value.u64()
    for byte in 0..<8:
        output[offset + byte] <- (bits & 255).u8()
        bits <- bits >> 8

def fmt_run(vertices: u16, graph: view[u16]) -> u64:
    complete: mutable bool = True
    for u in 0..<N:
        if ((vertices >> u) & 1) != 0:
            others: u16 = vertices & ~(1.u16 << u)
            if (graph[u] & others) != others: complete <- False
    if complete: return 0

    pivot: mutable usize = 0
    while pivot < N:
        if ((vertices >> pivot) & 1) != 0:
            others: u16 = vertices & ~(1.u16 << pivot)
            if (graph[pivot] & others) != others: break
        pivot <- pivot + 1
    a: u16 = (1.u16 << pivot) | (graph[pivot] & vertices)
    unseen: mutable u16 = vertices & ~a
    components: mutable u16[N] = zeroed
    closures: mutable u16[N] = zeroed
    count: mutable usize = 0
    while unseen != 0:
        seed: mutable usize = 0
        while ((unseen >> seed) & 1) == 0: seed <- seed + 1
        comp: mutable u16 = 1.u16 << seed
        unseen <- unseen & ~comp
        frontier: mutable u16 = comp
        while frontier != 0:
            u: mutable usize = 0
            while ((frontier >> u) & 1) == 0: u <- u + 1
            frontier <- frontier & ~(1.u16 << u)
            added: u16 = graph[u] & unseen
            comp <- comp | added
            frontier <- frontier | added
            unseen <- unseen & ~added
        components[count] <- comp
        count <- count + 1

    saturated: mutable u16[N] = zeroed
    for u in 0..<N: saturated[u] <- graph[u]
    result: mutable u64 = 0
    for ci in 0..<count:
        comp: u16 = components[ci]
        boundary: mutable u16 = 0
        for u in 0..<N:
            if ((comp >> u) & 1) != 0: boundary <- boundary | (graph[u] & vertices & ~comp)
        closures[ci] <- comp | boundary
        for u in 0..<N:
            if ((boundary >> u) & 1) != 0:
                v: mutable usize = u + 1
                while v < N:
                    if ((boundary >> v) & 1) != 0 and ((saturated[u] >> v) & 1) == 0:
                        saturated[u] <- saturated[u] | (1.u16 << v)
                        saturated[v] <- saturated[v] | (1.u16 << u)
                        result <- result | (1.u64 << (u * N + v))
                    v <- v + 1
    result <- result | fmt_run(a, saturated[0:N])
    for ci in 0..<count: result <- result | fmt_run(closures[ci], saturated[0:N])
    result

def fmt_impl(input: view[i64], output_ptr: mutable u8&, capacity: usize) -> i64:
    length: usize = input.len()
    if length < 2 or length > MAX_INPUT: return -1
    n64: i64 = input[0]; m64: i64 = input[1]
    if n64 < 1 or n64 > N.i64() or m64 < 0 or m64 > M.i64() or length != 2 + 2*m64.usize(): return -1
    n: usize = n64.usize(); m: usize = m64.usize()
    graph: mutable u16[N] = zeroed
    original: mutable u64 = 0
    previous_u: mutable i64 = -1; previous_v: mutable i64 = -1
    for edge in 0..<m:
        u64: i64 = input[2 + 2*edge]; v64: i64 = input[3 + 2*edge]
        if u64 < 0 or v64 <= u64 or v64 >= n64 or u64 < previous_u or (u64 == previous_u and v64 <= previous_v): return -1
        previous_u <- u64; previous_v <- v64
        u: usize = u64.usize(); v: usize = v64.usize()
        graph[u] <- graph[u] | (1.u16 << v); graph[v] <- graph[v] | (1.u16 << u)
        original <- original | (1.u64 << (u*N+v))
    fill: u64 = fmt_run(((1.u16 << n)-1), graph[0:N]) & ~original
    count: mutable usize = 0
    for u in 0..<n:
        for v in (u+1)..<n:
            if ((fill >> (u*N+v)) & 1) != 0: count <- count + 1
    bytes: usize = 8 * (1 + 2*count)
    if output_ptr.is_null() or capacity < bytes: return -2
    output: mutable view[u8] = output_ptr[0:bytes]
    fmt_store(output, 0, count.i64())
    index: mutable usize = 1
    for u in 0..<n:
        for v in (u+1)..<n:
            if ((fill >> (u*N+v)) & 1) != 0:
                fmt_store(output, 8*index, u.i64()); index <- index + 1
                fmt_store(output, 8*index, v.i64()); index <- index + 1
    bytes.i64()

@export("fast_minimal_triangulation")
fn fast_minimal_triangulation(input_ptr: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t, output_ptr: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input_ptr == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT: return -1
    input: view[i64] = input_ptr[0:length]
    fmt_impl(input, output_ptr, capacity)
