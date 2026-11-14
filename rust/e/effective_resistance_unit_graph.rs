// Uncompiled and unexecuted matrix-tree draft.
fn minor(lap: &[[i64; 6]; 6], n: usize, first: usize, second: usize) -> i64 {
    let mut matrix = [[0i64; 6]; 6];
    let mut row = 0;
    for i in 0..n {
        if i == first || i == second { continue; }
        let mut col = 0;
        for j in 0..n {
            if j != first && j != second { matrix[row][col] = lap[i][j]; col += 1; }
        }
        row += 1;
    }
    if row == 0 { return 1; }
    let mut previous = 1;
    for k in 0..row-1 {
        let pivot = matrix[k][k];
        if pivot == 0 { return 0; }
        for i in k+1..row {
            for j in k+1..row {
                matrix[i][j] = (matrix[i][j]*pivot - matrix[i][k]*matrix[k][j])/previous;
            }
        }
        for i in k+1..row { matrix[i][k] = 0; }
        previous = pivot;
    }
    matrix[row-1][row-1]
}

#[no_mangle]
pub unsafe extern "C" fn effective_resistance_unit_graph(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(4..=35).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (n, m, s, t) = (values[0], values[1], values[2], values[3]);
    if !(2..=6).contains(&n) || !(0..=15).contains(&m) || s < 0 || s >= n || t < 0 || t >= n || s == t || length != 4+2*m as usize { return -1; }
    let (n,m,s,t) = (n as usize,m as usize,s as usize,t as usize);
    let mut lap = [[0i64; 6]; 6];
    let mut seen = [[false; 6]; 6];
    for i in 0..m {
        let (u,v) = (values[4+2*i],values[5+2*i]);
        if u < 0 || u >= n as i64 || v < 0 || v >= n as i64 || u == v { return -1; }
        let (u,v) = (u as usize,v as usize);
        if seen[u][v] { return -1; }
        seen[u][v] = true; seen[v][u] = true;
        lap[u][u] += 1; lap[v][v] += 1; lap[u][v] -= 1; lap[v][u] -= 1;
    }
    let trees = minor(&lap,n,t,n);
    if trees <= 0 { return -1; }
    let forests = minor(&lap,n,s,t);
    let (mut a,mut b) = (trees,forests);
    while b != 0 { let r = a%b; a = b; b = r; }
    forests/a*65536 + trees/a
}
