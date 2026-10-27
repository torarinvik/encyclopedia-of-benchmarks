use std::slice;

fn put_i64(out: &mut [u8], value: i64) { out.copy_from_slice(&value.to_le_bytes()); }

#[no_mangle]
pub unsafe extern "C" fn felsenstein_substitution_likelihood(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > 38 { return -1; }
    let a = slice::from_raw_parts(input, length);
    let n = a[0];
    if !(1..=8).contains(&n) { return -1; }
    let mut stack = [[0i64; 2]; 8];
    let (mut sp, mut leaves, mut joins, mut edges) = (0usize, 0i64, 0i64, 0i64);
    let mut at = 1usize;
    while at < length {
        let tag = a[at]; at += 1;
        if tag == 0 {
            if at >= length || !(0..=1).contains(&a[at]) || sp >= 8 { return -1; }
            stack[sp] = if a[at] == 0 { [1,0] } else { [0,1] };
            at += 1; sp += 1; leaves += 1;
        } else if tag == 1 {
            if at + 2 > length || sp < 2 || !(0..=1).contains(&a[at]) || !(0..=1).contains(&a[at+1]) { return -1; }
            let lm = a[at]; let rm = a[at+1]; at += 2;
            let left = stack[sp-2]; let right = stack[sp-1];
            let mut next = [0i64; 2];
            for parent in 0..2 {
                let l = if lm == 0 { 4*left[parent] } else { 3*left[parent]+left[1-parent] };
                let r = if rm == 0 { 4*right[parent] } else { 3*right[parent]+right[1-parent] };
                next[parent] = l*r;
            }
            stack[sp-2] = next; sp -= 1; joins += 1; edges += 2;
        } else { return -1; }
    }
    if leaves != n || joins != n-1 || sp != 1 || edges != 2*n-2 { return -1; }
    let shift = 29 - 2*edges;
    if shift < 0 { return -1; }
    let scaled = (stack[0][0]+stack[0][1]) << shift;
    if output.is_null() || capacity < 8 { return -2; }
    put_i64(slice::from_raw_parts_mut(output,8), scaled);
    8
}
