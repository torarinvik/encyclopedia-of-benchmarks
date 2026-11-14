fn add(tree: &mut [i64], position: usize, delta: i64) {
    let mut i = position + 1;
    while i < tree.len() { tree[i] += delta; i += i & i.wrapping_neg(); }
}

fn prefix(tree: &[i64], mut end: usize) -> i64 {
    let mut sum = 0;
    while end != 0 { sum += tree[end]; end &= end - 1; }
    sum
}

#[no_mangle]
pub unsafe extern "C" fn offline_range_distinct_fenwick(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(3..=195).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (nr, qr) = (values[0], values[1]);
    if !(1..=64).contains(&nr) || !(0..=64).contains(&qr) { return -1; }
    let (n, q) = (nr as usize, qr as usize);
    if length != 2+n+2*q || values[2..2+n].iter().any(|&x| !(0..=255).contains(&x)) { return -1; }
    let mut head = [None; 65];
    let mut next = [None; 64];
    for i in 0..q {
        let (left,right) = (values[2+n+2*i], values[3+n+2*i]);
        if left < 0 || left > right || right > nr { return -1; }
        next[i] = head[right as usize]; head[right as usize] = Some(i);
    }
    let mut tree = [0i64; 65];
    let mut last = [None; 256];
    let mut result = 0;
    for right in 0..=n {
        if right > 0 {
            let value = values[1+right] as usize;
            if let Some(previous) = last[value] { add(&mut tree[..=n], previous, -1); }
            add(&mut tree[..=n], right-1, 1); last[value] = Some(right-1);
        }
        let mut query = head[right];
        while let Some(i) = query {
            let left = values[2+n+2*i] as usize;
            result += (i as i64+1)*(prefix(&tree,right)-prefix(&tree,left));
            query = next[i];
        }
    }
    result
}
