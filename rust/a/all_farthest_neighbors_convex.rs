fn score(points: &[(i64,i64)], row: usize, col: usize) -> i64 {
    let n = points.len();
    if col <= row { return col as i64-row as i64; }
    if col >= row+n { return -1; }
    let (x,y) = points[row]; let (u,v) = points[col%n];
    (x-u)*(x-u)+(y-v)*(y-v)
}
fn maxima(points: &[(i64,i64)], rows: &[usize], columns: &[usize], answer: &mut [usize]) {
    if rows.is_empty() { return; }
    let mut reduced = Vec::with_capacity(rows.len());
    for &col in columns {
        while !reduced.is_empty() && score(points,rows[reduced.len()-1],col) >
              score(points,rows[reduced.len()-1],*reduced.last().unwrap()) { reduced.pop(); }
        if reduced.len() < rows.len() { reduced.push(col); }
    }
    let odd: Vec<_> = rows.iter().skip(1).step_by(2).copied().collect();
    maxima(points,&odd,&reduced,answer);
    let mut low = 0;
    for i in (0..rows.len()).step_by(2) {
        let mut high = reduced.len()-1;
        if i+1 < rows.len() {
            high = low;
            while reduced[high] != answer[rows[i+1]] { high += 1; }
        }
        let mut best = low;
        for j in low+1..=high {
            if score(points,rows[i],reduced[j]) > score(points,rows[i],reduced[best]) { best = j; }
        }
        answer[rows[i]] = reduced[best];
        low = high;
    }
}
#[no_mangle]
pub unsafe extern "C" fn all_farthest_neighbors_convex(input: *const i64, length: usize,
                                                        output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || !(7..=129).contains(&length) { return -1; }
    let f = std::slice::from_raw_parts(input,length);
    if !(3..=64).contains(&f[0]) { return -1; }
    let n = f[0] as usize;
    if length != 1+2*n { return -1; }
    let mut points = Vec::with_capacity(n);
    for pair in f[1..].chunks_exact(2) {
        if !(-1_000_000..=1_000_000).contains(&pair[0]) || !(-1_000_000..=1_000_000).contains(&pair[1]) { return -1; }
        points.push((pair[0],pair[1]));
    }
    for i in 0..n {
        let (a,b,c) = (points[i],points[(i+1)%n],points[(i+2)%n]);
        if (b.0-a.0)*(c.1-b.1)-(b.1-a.1)*(c.0-b.0) >= 0 { return -1; }
    }
    if output.is_null() || capacity < 8*n { return -2; }
    let rows: Vec<_> = (0..n).collect(); let columns: Vec<_> = (0..2*n-1).collect();
    let mut answer = vec![0; n];
    maxima(&points,&rows,&columns,&mut answer);
    for (i,&col) in answer.iter().enumerate() {
        std::ptr::copy_nonoverlapping(((col%n) as i64).to_le_bytes().as_ptr(),output.add(8*i),8);
    }
    (8*n) as i64
}
