/// Emit the nearest strictly smaller value to the left of every input value.
fn put_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset+8].copy_from_slice(&value.to_le_bytes());
}
#[no_mangle]
pub unsafe extern "C" fn next_smaller_element(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 { return -1; }
    let packed = std::slice::from_raw_parts(input, length);
    if !(0..=1024).contains(&packed[0]) || length != packed[0] as usize + 1 || packed[1..].iter().any(|v| *v < i32::MIN as i64 || *v > i32::MAX as i64) { return -1; }
    let n=packed[0] as usize;
    if capacity<n*8 || (n>0 && output.is_null()) { return -2; }
    if n == 0 { return 0; }
    let out=std::slice::from_raw_parts_mut(output,n*8);
    let mut stack: Vec<i64>=Vec::with_capacity(n);
    for (i,&value) in packed[1..].iter().enumerate() {
        while let Some(&top) = stack.last() { if top < value { break; } stack.pop(); }
        put_i64_le(out,i*8,stack.last().copied().unwrap_or(-1));
        stack.push(value);
    }
    (n*8) as i64
}
