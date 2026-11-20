/* Bounded clean-room connected/co-connected cograph cotree profile. */
const N: usize = 12;
const M: usize = 66;
const PARSEABLE: usize = 135;
const OUT: usize = 47;

fn components(mask: u16, adjacency: &[u16; N], complement: bool,
              parts: &mut [u16; N]) -> usize {
    let mut remaining = mask;
    let mut count = 0;
    for root in 0..N {
        let root_bit = 1u16 << root;
        if remaining & root_bit == 0 { continue; }
        let mut reached = root_bit;
        let mut queue = [0usize; N];
        let mut head = 0;
        let mut tail = 1;
        queue[0] = root;
        while head < tail {
            let vertex = queue[head];
            head += 1;
            let neighbors = if complement {
                mask & !adjacency[vertex] & !(1u16 << vertex)
            } else {
                adjacency[vertex] & mask
            };
            let mut fresh = neighbors & !reached;
            for next in 0..N {
                let bit = 1u16 << next;
                if fresh & bit != 0 {
                    fresh &= !bit;
                    reached |= bit;
                    queue[tail] = next;
                    tail += 1;
                }
            }
        }
        parts[count] = reached;
        count += 1;
        remaining &= !reached;
    }
    count
}

fn emit(mask: u16, adjacency: &[u16; N], output: &mut [u8; OUT], position: &mut usize) -> bool {
    if mask & (mask - 1) == 0 {
        output[*position] = 0;
        output[*position + 1] = mask.trailing_zeros() as u8;
        *position += 2;
        return true;
    }
    let mut parts = [0u16; N];
    let mut count = components(mask, adjacency, false, &mut parts);
    let mut kind = 1u8;
    if count == 1 {
        count = components(mask, adjacency, true, &mut parts);
        kind = 2;
        if count <= 1 { return false; }
    }
    output[*position] = kind;
    output[*position + 1] = count as u8;
    *position += 2;
    for child in parts.iter().take(count) {
        if !emit(*child, adjacency, output, position) { return false; }
    }
    true
}

#[no_mangle]
pub unsafe extern "C" fn cograph_cotree_decomposition(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > PARSEABLE { return -1; }
    let n64 = *input;
    let m64 = *input.add(1);
    if n64 < 1 || n64 > N as i64 || m64 < 0 || m64 > M as i64 || m64 > n64 * (n64 - 1) / 2 ||
        length != 2 + 2 * m64 as usize { return -1; }
    let n = n64 as usize;
    let m = m64 as usize;
    let mut adjacency = [0u16; N];
    for edge in 0..m {
        let u64 = *input.add(2 + 2 * edge);
        let v64 = *input.add(3 + 2 * edge);
        if u64 < 0 || u64 >= n as i64 || v64 < 0 || v64 >= n as i64 || u64 == v64 { return -1; }
        let u = u64 as usize;
        let v = v64 as usize;
        if adjacency[u] & (1u16 << v) != 0 { return -1; }
        adjacency[u] |= 1u16 << v;
        adjacency[v] |= 1u16 << u;
    }
    let mut staged = [0u8; OUT];
    let mut output_length = 1usize;
    if emit((1u16 << n) - 1, &adjacency, &mut staged, &mut output_length) {
        staged[0] = 1;
    } else {
        staged[0] = 0;
        output_length = 1;
    }
    if output.is_null() || capacity < output_length { return -2; }
    for i in 0..output_length { *output.add(i) = staged[i]; }
    output_length as i64
}
