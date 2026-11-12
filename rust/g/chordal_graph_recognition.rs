const N: usize = 6;
const MAX_INPUT: usize = 32;
const MAX_OUTPUT: usize = 64;

fn put_u64(out: &mut [u8; MAX_OUTPUT], index: usize, value: u64) {
    for byte in 0..8 { out[index * 8 + byte] = (value >> (byte * 8)) as u8; }
}

fn induced_cycle(adjacent: &[[bool; N]; N], n: usize) -> Option<Vec<usize>> {
    for mask in 0usize..(1usize << n) {
        let vertices: Vec<usize> = (0..n).filter(|v| mask & (1 << v) != 0).collect();
        let count = vertices.len();
        if count < 4 || vertices.iter().any(|&v| vertices.iter().filter(|&&u| adjacent[v][u]).count() != 2) { continue; }
        let mut seen = [false; N];
        let mut queue = [0usize; N];
        let (mut head, mut tail) = (0usize, 1usize);
        seen[vertices[0]] = true;
        queue[0] = vertices[0];
        while head < tail {
            let v = queue[head]; head += 1;
            for &u in &vertices {
                if adjacent[v][u] && !seen[u] { seen[u] = true; queue[tail] = u; tail += 1; }
            }
        }
        if tail != count { continue; }
        let start = vertices[0];
        let mut cycle = vec![start];
        let mut previous = start;
        let mut current = *vertices.iter().find(|&&u| adjacent[start][u]).unwrap();
        while current != start {
            cycle.push(current);
            let next = *vertices.iter().find(|&&u| adjacent[current][u] && u != previous).unwrap();
            previous = current;
            current = next;
        }
        return Some(cycle);
    }
    None
}

fn mcs_order(adjacent: &[[bool; N]; N], n: usize) -> [usize; N] {
    let mut selected = [false; N];
    let mut label = [0usize; N];
    let mut reverse = [0usize; N];
    for step in 0..n {
        let mut chosen = usize::MAX;
        for v in 0..n {
            if !selected[v] && (chosen == usize::MAX || label[v] > label[chosen]) { chosen = v; }
        }
        selected[chosen] = true;
        reverse[step] = chosen;
        for u in 0..n { if !selected[u] && adjacent[chosen][u] { label[u] += 1; } }
    }
    let mut order = [0usize; N];
    for i in 0..n { order[i] = reverse[n - i - 1]; }
    order
}

fn is_peo(adjacent: &[[bool; N]; N], order: &[usize; N], n: usize) -> bool {
    let mut position = [0usize; N];
    for i in 0..n { position[order[i]] = i; }
    for i in 0..n {
        let v = order[i];
        let mut parent = usize::MAX;
        for u in 0..n {
            if adjacent[v][u] && position[u] > i && (parent == usize::MAX || position[u] < position[parent]) { parent = u; }
        }
        if parent != usize::MAX {
            for u in 0..n { if adjacent[v][u] && position[u] > i && u != parent && !adjacent[parent][u] { return false; } }
        }
    }
    true
}

#[no_mangle]
pub unsafe extern "C" fn chordal_graph_recognition(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(1..=N as i64).contains(&values[0]) || !(0..=15).contains(&values[1]) { return -1; }
    let n = values[0] as usize;
    let m = values[1] as usize;
    if m > n * (n - 1) / 2 || length != 2 + 2 * m { return -1; }
    let mut adjacent = [[false; N]; N];
    for edge in 0..m {
        let (a0, b0) = (values[2 + 2 * edge], values[3 + 2 * edge]);
        if a0 < 0 || b0 < 0 || a0 >= n as i64 || b0 >= n as i64 || a0 == b0 { return -1; }
        let (a, b) = (a0 as usize, b0 as usize);
        if adjacent[a][b] { return -1; }
        adjacent[a][b] = true; adjacent[b][a] = true;
    }
    let order = mcs_order(&adjacent, n);
    let mut packed = [0u64; 8];
    let mut count = 0usize;
    if is_peo(&adjacent, &order, n) {
        packed[count] = 1; count += 1;
        for &vertex in &order[..n] { packed[count] = vertex as u64; count += 1; }
    } else {
        let cycle = match induced_cycle(&adjacent, n) { Some(cycle) => cycle, None => return -1 };
        packed[count] = 0; count += 1;
        packed[count] = cycle.len() as u64; count += 1;
        for vertex in cycle { packed[count] = vertex as u64; count += 1; }
    }
    let bytes = count * 8;
    if output.is_null() || capacity < bytes { return -2; }
    let mut staged = [0u8; MAX_OUTPUT];
    for i in 0..count { put_u64(&mut staged, i, packed[i]); }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, bytes);
    bytes as i64
}
