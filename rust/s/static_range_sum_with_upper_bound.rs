#[no_mangle]
pub unsafe extern "C" fn static_range_sum_with_upper_bound(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(2..=258).contains(&length) { return -1; }
    let frame = std::slice::from_raw_parts(input, length);
    if !(1..=64).contains(&frame[0]) || !(1..=64).contains(&frame[1]) { return -1; }
    let n = frame[0] as usize;
    let q = frame[1] as usize;
    if length != 2+n+3*q { return -1; }
    if frame[2..2+n].iter().any(|&v| !(0..=1_000_000_000).contains(&v)) { return -1; }
    for query in frame[2+n..].chunks_exact(3) {
        if query[0] < 0 || query[0] > query[1] || query[1] > n as i64 ||
           !(0..=1_000_000_000).contains(&query[2]) { return -1; }
    }
    if output.is_null() || capacity < 16*q { return -2; }
    let mut order: Vec<u32> = frame[2..2+n].iter().map(|&v| v as u32).collect();
    let mut counts = [[0usize; 65]; 30];
    let mut sums = [[0u64; 65]; 30];
    let mut offsets = [0usize; 30];
    for level in 0..30 {
        let mask = 1u32 << (29-level);
        for (i, &value) in order.iter().enumerate() {
            let zero = value & mask == 0;
            counts[level][i+1] = counts[level][i] + usize::from(zero);
            sums[level][i+1] = sums[level][i] + if zero { value as u64 } else { 0 };
        }
        offsets[level] = counts[level][n];
        let mut next = Vec::with_capacity(n);
        next.extend(order.iter().copied().filter(|x| x & mask == 0));
        next.extend(order.iter().copied().filter(|x| x & mask != 0));
        order = next;
    }
    for (i, query) in frame[2+n..].chunks_exact(3).enumerate() {
        let (mut l, mut r) = (query[0] as usize, query[1] as usize);
        let threshold = query[2] as u32 + 1;
        let (mut count, mut sum) = (0u64, 0u64);
        for level in 0..30 {
            let (zl, zr) = (counts[level][l], counts[level][r]);
            if threshold & (1u32 << (29-level)) != 0 {
                count += (zr-zl) as u64;
                sum += sums[level][r]-sums[level][l];
                l += offsets[level]-zl;
                r += offsets[level]-zr;
            } else { l = zl; r = zr; }
        }
        std::ptr::copy_nonoverlapping(count.to_le_bytes().as_ptr(), output.add(16*i), 8);
        std::ptr::copy_nonoverlapping(sum.to_le_bytes().as_ptr(), output.add(16*i+8), 8);
    }
    (16*q) as i64
}
