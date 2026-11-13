fn root(parent: &mut [usize; 36], mut x: usize) -> usize {
    while parent[x] != x { parent[x] = parent[parent[x]]; x = parent[x]; }
    x
}

#[no_mangle]
pub unsafe extern "C" fn statistical_region_merging_table(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(4..=74).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(1..=6).contains(&values[0]) || !(1..=6).contains(&values[1]) { return -1; }
    let width = values[1] as usize;
    let n = values[0] as usize * width;
    if length != 2 + 2*n || values[2..2+n].iter().any(|x| !(0..=65535).contains(x))
        || values[2+n..].iter().any(|x| !(0..=255).contains(x)) { return -1; }
    let mut parent = [0usize; 36];
    let mut sizes = [1usize; 36];
    let mut minimum = [0usize; 36];
    let mut sums = [0i64; 36];
    for i in 0..n { parent[i] = i; minimum[i] = i; sums[i] = values[2+n+i]; }
    for diff in 0..256 {
        for p in 0..n {
            let mut neighbors = [0usize; 2];
            let mut count = 0;
            if p % width + 1 < width { neighbors[count] = p+1; count += 1; }
            if p + width < n { neighbors[count] = p+width; count += 1; }
            for &q in &neighbors[..count] {
                if (values[2+n+p] - values[2+n+q]).abs() != diff { continue; }
                let (mut a, mut b) = (root(&mut parent, p), root(&mut parent, q));
                if a == b { continue; }
                let (na, nb) = (sizes[a] as i64, sizes[b] as i64);
                let delta = sums[a]*nb - sums[b]*na;
                let bound = values[1+sizes[a]] + values[1+sizes[b]];
                if delta*delta > bound*na*na*nb*nb { continue; }
                if sizes[a] < sizes[b] { std::mem::swap(&mut a, &mut b); }
                parent[b] = a; sizes[a] += sizes[b]; sums[a] += sums[b]; minimum[a] = minimum[a].min(minimum[b]);
            }
        }
    }
    if output.is_null() || capacity < n { return -2; }
    let out = std::slice::from_raw_parts_mut(output, n);
    for (i, byte) in out.iter_mut().enumerate() { *byte = minimum[root(&mut parent, i)] as u8; }
    n as i64
}
