const PRIME: i64 = 2_147_483_647;

fn put_i64_le(out: &mut [u8], offset: usize, value: i64) {
    out[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn count_min_sketch_affine(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > 59 { return -1; }
    let v = unsafe { core::slice::from_raw_parts(input, length) };
    let (d0, w0, q0) = (v[0], v[1], v[2]);
    if !(1..=4).contains(&d0) || !(1..=8).contains(&w0) || !(0..=16).contains(&q0) { return -1; }
    let (d, w, ops) = (d0 as usize, w0 as usize, q0 as usize);
    let start = 3 + 2*d;
    if length != start + 3*ops { return -1; }
    let mut a = [0i64; 4]; let mut b = [0i64; 4];
    for r in 0..d {
        a[r] = v[3 + 2*r]; b[r] = v[4 + 2*r];
        if a[r] < 1 || a[r] >= PRIME || b[r] < 0 || b[r] >= PRIME { return -1; }
    }
    let mut query_count = 0usize;
    for op in 0..ops {
        let (kind,key,weight) = (v[start+3*op], v[start+3*op+1], v[start+3*op+2]);
        if !(0..=1_000_000).contains(&key) { return -1; }
        if kind == 0 { if !(1..=1_000_000).contains(&weight) { return -1; } }
        else if kind == 1 { if weight != 0 { return -1; } query_count += 1; }
        else { return -1; }
    }
    let mut table = [[0i64; 8]; 4];
    let mut staged = [0i64; 16]; let mut result_count = 0usize;
    for op in 0..ops {
        let (kind,key,weight) = (v[start+3*op], v[start+3*op+1], v[start+3*op+2]);
        let mut slots = [0usize; 4];
        for r in 0..d { slots[r] = (((a[r]*key+b[r]) % PRIME) % w as i64) as usize; }
        if kind == 0 { for r in 0..d { table[r][slots[r]] += weight; } }
        else {
            let mut minimum = table[0][slots[0]];
            for r in 1..d { if table[r][slots[r]] < minimum { minimum = table[r][slots[r]]; } }
            staged[result_count] = minimum; result_count += 1;
        }
    }
    let required = query_count * 8;
    if capacity < required || (required > 0 && output.is_null()) { return -2; }
    if required > 0 {
        let out = unsafe { core::slice::from_raw_parts_mut(output, required) };
        for i in 0..result_count { put_i64_le(out, 8*i, staged[i]); }
    }
    required as i64
}
