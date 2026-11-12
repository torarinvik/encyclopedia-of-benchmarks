const MAX_V: usize = 16;
const MAX_E: usize = 32;
const MAX_INPUT: usize = 66;
const MAX_OUTPUT: usize = 17;

#[no_mangle]
pub unsafe extern "C" fn games_on_arbitrary_graphs(
    input_ptr: *const i64,
    length: usize,
    output_ptr: *mut u8,
    capacity: usize,
) -> i64 {
    if input_ptr.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let input = std::slice::from_raw_parts(input_ptr, length);
    let (nv, me) = (input[0], input[1]);
    if nv < 0 || nv > MAX_V as i64 || me < 0 || me > MAX_E as i64 { return -1; }
    let (n, m) = (nv as usize, me as usize);
    if length != 2 + 2 * m { return -1; }

    let mut outmask = [0u16; MAX_V];
    let mut head = [-1i32; MAX_V];
    let mut edge_source = [0usize; MAX_E];
    let mut edge_next = [-1i32; MAX_E];
    let mut remaining = [0usize; MAX_V];
    let mut status = [0u8; MAX_V];
    let mut queue = [0usize; MAX_V];
    let mut staged = [0u8; MAX_OUTPUT];
    let mut unique_edges = 0usize;

    for i in 0..m {
        let (sv, tv) = (input[2 + 2 * i], input[3 + 2 * i]);
        if sv < 0 || sv >= nv || tv < 0 || tv >= nv { return -1; }
        let (s, t) = (sv as usize, tv as usize);
        let bit = 1u16 << t;
        if outmask[s] & bit == 0 {
            outmask[s] |= bit;
            edge_source[unique_edges] = s;
            edge_next[unique_edges] = head[t];
            head[t] = unique_edges as i32;
            unique_edges += 1;
            remaining[s] += 1;
        }
    }

    let (mut first, mut count) = (0usize, 0usize);
    for v in 0..n {
        if remaining[v] == 0 {
            status[v] = 2;
            queue[count] = v;
            count += 1;
        }
    }
    while first < count {
        let resolved = queue[first];
        first += 1;
        let mut edge = head[resolved];
        while edge >= 0 {
            let index = edge as usize;
            let predecessor = edge_source[index];
            if status[predecessor] == 0 {
                if status[resolved] == 2 {
                    status[predecessor] = 1;
                    queue[count] = predecessor;
                    count += 1;
                } else {
                    remaining[predecessor] -= 1;
                    if remaining[predecessor] == 0 {
                        status[predecessor] = 2;
                        queue[count] = predecessor;
                        count += 1;
                    }
                }
            }
            edge = edge_next[index];
        }
    }

    staged[0] = n as u8;
    for vertex in 0..n { staged[vertex + 1] = status[vertex]; }
    let needed = n + 1;
    if output_ptr.is_null() || capacity < needed { return -2; }
    let output = std::slice::from_raw_parts_mut(output_ptr, needed);
    output.copy_from_slice(&staged[..needed]);
    needed as i64
}
