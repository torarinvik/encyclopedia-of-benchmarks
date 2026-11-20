use std::slice;

const N: usize = 8;
const M: usize = 28;
const MAX_INPUT: usize = 59;

fn recurse(vertices: u16, graph: [u16; N]) -> u64 {
    let mut complete = true;
    for u in 0..N {
        if vertices & (1 << u) != 0 {
            let others = vertices & !(1 << u);
            if graph[u] & others != others { complete = false; }
        }
    }
    if complete { return 0; }
    let mut pivot = 0usize;
    while vertices & (1 << pivot) == 0 || graph[pivot] & (vertices & !(1 << pivot)) == (vertices & !(1 << pivot)) { pivot += 1; }
    let a = (1u16 << pivot) | (graph[pivot] & vertices);
    let mut unseen = vertices & !a;
    let mut components = [0u16; N];
    let mut closures = [0u16; N];
    let mut count = 0usize;
    while unseen != 0 {
        let seed = unseen.trailing_zeros() as usize;
        let mut comp = 1u16 << seed;
        unseen &= !comp;
        let mut frontier = comp;
        while frontier != 0 {
            let u = frontier.trailing_zeros() as usize;
            frontier &= !(1 << u);
            let added = graph[u] & unseen;
            comp |= added;
            frontier |= added;
            unseen &= !added;
        }
        components[count] = comp;
        count += 1;
    }
    let mut saturated = graph;
    let mut result = 0u64;
    for ci in 0..count {
        let comp = components[ci];
        let mut boundary = 0u16;
        for u in 0..N {
            if comp & (1 << u) != 0 { boundary |= graph[u] & vertices & !comp; }
        }
        closures[ci] = comp | boundary;
        for u in 0..N {
            if boundary & (1 << u) == 0 { continue; }
            for v in u + 1..N {
                if boundary & (1 << v) != 0 && saturated[u] & (1 << v) == 0 {
                    saturated[u] |= 1 << v;
                    saturated[v] |= 1 << u;
                    result |= 1u64 << (u * N + v);
                }
            }
        }
    }
    result |= recurse(a, saturated);
    for closure in closures.iter().take(count) { result |= recurse(*closure, saturated); }
    result
}

fn put_word(output: &mut [u8], at: usize, value: i64) {
    output[at..at + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn fast_minimal_triangulation(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let values = slice::from_raw_parts(input, length);
    let (n64, m64) = (values[0], values[1]);
    if n64 < 1 || n64 > N as i64 || m64 < 0 || m64 > M as i64 || length != 2 + 2 * m64 as usize { return -1; }
    let (n, m) = (n64 as usize, m64 as usize);
    let mut graph = [0u16; N];
    let mut original = 0u64;
    let mut previous = (-1i64, -1i64);
    for i in 0..m {
        let (u, v) = (values[2 + 2 * i], values[3 + 2 * i]);
        if u < 0 || v <= u || v >= n64 || u < previous.0 || (u == previous.0 && v <= previous.1) { return -1; }
        previous = (u, v);
        graph[u as usize] |= 1 << v;
        graph[v as usize] |= 1 << u;
        original |= 1u64 << (u as usize * N + v as usize);
    }
    let fill = recurse(((1u16 << n) - 1), graph) & !original;
    let mut count = 0usize;
    for u in 0..n { for v in u + 1..n { if fill & (1u64 << (u * N + v)) != 0 { count += 1; } } }
    let bytes = 8 * (1 + 2 * count);
    if output.is_null() || capacity < bytes { return -2; }
    let out = slice::from_raw_parts_mut(output, bytes);
    put_word(out, 0, count as i64);
    let mut index = 1;
    for u in 0..n { for v in u + 1..n {
        if fill & (1u64 << (u * N + v)) != 0 {
            put_word(out, 8 * index, u as i64); index += 1;
            put_word(out, 8 * index, v as i64); index += 1;
        }
    }}
    bytes as i64
}
