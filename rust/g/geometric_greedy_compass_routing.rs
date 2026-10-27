const MAX_N: usize = 8;
const MAX_INPUT: usize = 84;
const MAX_OUTPUT: usize = 80;
const OUTPUT_VALUES: usize = 10;

unsafe fn put64(output: *mut u8, position: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(position + byte) = (bits >> (8 * byte)) as u8; }
}

fn angle_better(da: i64, la: i64, db: i64, lb: i64) -> bool {
    if (da >= 0) != (db >= 0) { return da >= 0; }
    let left = da * da * lb; let right = db * db * la;
    if da >= 0 { left > right } else { left < right }
}
fn angle_equal(da: i64, la: i64, db: i64, lb: i64) -> bool {
    (da >= 0) == (db >= 0) && da * da * lb == db * db * la
}

#[no_mangle]
pub unsafe extern "C" fn geometric_greedy_compass_routing(input: *const i64,
    length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 12 || length > MAX_INPUT { return -1; }
    let n64 = *input; let mode = *input.add(1); let source64 = *input.add(2); let target64 = *input.add(3);
    if n64 < 2 || n64 > MAX_N as i64 || mode < 0 || mode > 1 || source64 < 0 || target64 < 0 || source64 >= n64 || target64 >= n64 { return -1; }
    let n = n64 as usize; let source = source64 as usize; let target = target64 as usize;
    if length != 4 + 2*n + n*n { return -1; }
    let adjacency = 4 + 2*n;
    let mut x = [0i64; MAX_N]; let mut y = [0i64; MAX_N];
    for i in 0..n {
        x[i] = *input.add(4+i); y[i] = *input.add(4+n+i);
        if x[i] < -8 || x[i] > 8 || y[i] < -8 || y[i] > 8 { return -1; }
        for j in 0..i { if x[i] == x[j] && y[i] == y[j] { return -1; } }
    }
    for i in 0..n { for j in 0..n {
        let a = *input.add(adjacency+i*n+j); let b = *input.add(adjacency+j*n+i);
        if (a != 0 && a != 1) || a != b || (i == j && a != 0) { return -1; }
    }}
    if output.is_null() || capacity < MAX_OUTPUT { return -2; }
    let mut path = [0usize; MAX_N]; let mut count = 1usize;
    let mut visited = [false; MAX_N]; path[0] = source; visited[source] = true;
    let mut current = source;
    while current != target && count < n {
        let mut best = n; let mut best_dot = 0i64; let mut best_len = 1i64; let mut best_distance = 0i64;
        let tx = x[target]-x[current]; let ty = y[target]-y[current];
        for v in 0..n {
            if *input.add(adjacency+current*n+v) != 1 { continue; }
            let mut better = best == n;
            let dx = x[v]-x[current]; let dy = y[v]-y[current];
            if mode == 0 {
                let rx = x[v]-x[target]; let ry = y[v]-y[target]; let distance = rx*rx+ry*ry;
                if !better { better = distance < best_distance || (distance == best_distance && v < best); }
                if better { best_distance = distance; }
            } else {
                let dot = dx*tx+dy*ty; let len = dx*dx+dy*dy;
                if !better { better = angle_better(dot,len,best_dot,best_len) || (angle_equal(dot,len,best_dot,best_len) && v < best); }
                if better { best_dot = dot; best_len = len; }
            }
            if better { best = v; }
        }
        if best == n || visited[best] { break; }
        path[count] = best; count += 1; visited[best] = true; current = best;
    }
    let mut record = [0i64; OUTPUT_VALUES];
    record[0] = if current == target { 1 } else { 0 }; record[1] = (count-1) as i64;
    for i in 0..MAX_N { record[2+i] = -1; }
    for i in 0..count { record[2+i] = path[i] as i64; }
    let mut staged = [0u8; MAX_OUTPUT];
    for i in 0..OUTPUT_VALUES { put64(staged.as_mut_ptr(),8*i,record[i]); }
    for i in 0..MAX_OUTPUT { *output.add(i) = staged[i]; }
    MAX_OUTPUT as i64
}
