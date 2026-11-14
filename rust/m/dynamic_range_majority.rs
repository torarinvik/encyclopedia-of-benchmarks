use std::collections::BTreeMap;

fn combine(a: (i64, usize), b: (i64, usize)) -> (i64, usize) {
    if a.1 == 0 { return b; }
    if b.1 == 0 { return a; }
    if a.0 == b.0 { return (a.0, a.1+b.1); }
    if a.1 >= b.1 { (a.0, a.1-b.1) } else { (b.0, b.1-a.1) }
}

#[no_mangle]
pub unsafe extern "C" fn dynamic_range_majority(input: *const i64, length: usize,
                                               output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || !(2..=258).contains(&length) { return -1; }
    let f = std::slice::from_raw_parts(input, length);
    if !(1..=64).contains(&f[0]) || !(1..=64).contains(&f[1]) { return -1; }
    let (n,q) = (f[0] as usize, f[1] as usize);
    if length != 2+n+3*q || f[2..2+n].iter().any(|&x| !(0..=1_000_000_000).contains(&x)) { return -1; }
    let mut queries = 0;
    for op in f[2+n..].chunks_exact(3) {
        match op[0] {
            0 if (0..n as i64).contains(&op[1]) && (0..=1_000_000_000).contains(&op[2]) => (),
            1 if 0 <= op[1] && op[1] < op[2] && op[2] <= n as i64 => queries += 1,
            _ => return -1,
        }
    }
    if queries == 0 { return -1; }
    if output.is_null() || capacity < 8*queries { return -2; }
    let mut tree = [(0i64,0usize); 128];
    let mut data = f[2..2+n].to_vec();
    let mut masks = BTreeMap::<i64,u64>::new();
    for (i, &value) in data.iter().enumerate() {
        tree[64+i] = (value,1);
        *masks.entry(value).or_default() |= 1u64 << i;
    }
    for i in (1..64).rev() { tree[i] = combine(tree[2*i],tree[2*i+1]); }
    let mut written = 0;
    for op in f[2+n..].chunks_exact(3) {
        if op[0] == 0 {
            let p = op[1] as usize;
            *masks.get_mut(&data[p]).unwrap() &= !(1u64 << p);
            *masks.entry(op[2]).or_default() |= 1u64 << p;
            data[p] = op[2];
            let mut i = 64+p; tree[i] = (op[2],1);
            while i > 1 { i /= 2; tree[i] = combine(tree[2*i],tree[2*i+1]); }
        } else {
            let (lo,hi) = (op[1] as usize, op[2] as usize);
            let (mut l,mut r) = (lo+64,hi+64);
            let (mut a,mut b) = ((0,0),(0,0));
            while l < r {
                if l & 1 != 0 { a = combine(a,tree[l]); l += 1; }
                if r & 1 != 0 { r -= 1; b = combine(tree[r],b); }
                l /= 2; r /= 2;
            }
            let candidate = combine(a,b);
            let prefix = |p: usize| if p == 64 { u64::MAX } else { (1u64 << p)-1 };
            let selected = masks.get(&candidate.0).copied().unwrap_or(0) & (prefix(hi)^prefix(lo));
            let answer = if candidate.1 > 0 && 2*selected.count_ones() as usize > hi-lo { candidate.0 } else { -1 };
            std::ptr::copy_nonoverlapping(answer.to_le_bytes().as_ptr(), output.add(8*written), 8);
            written += 1;
        }
    }
    (8*written) as i64
}
