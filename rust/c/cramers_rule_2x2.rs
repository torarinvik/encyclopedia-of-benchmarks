const LIMIT: i64 = 1_000_000;

unsafe fn write_f64_le(output: *mut u8, offset: usize, value: f64) {
    let bytes = value.to_le_bytes();
    for byte in 0..8 { *output.add(offset + byte) = bytes[byte]; }
}

#[no_mangle]
pub unsafe extern "C" fn cramers_rule_2x2(
    v: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if v.is_null() || length != 6 { return -1; }
    for i in 0..6 {
        let value = *v.add(i);
        if value < -LIMIT || value > LIMIT { return -1; }
    }
    let a1=*v; let b1=*v.add(1); let c1=*v.add(2);
    let a2=*v.add(3); let b2=*v.add(4); let c2=*v.add(5);
    let d=a1*b2-a2*b1; let dx=c1*b2-c2*b1; let dy=a1*c2-a2*c1;
    if d == 0 { return -1; }
    if output.is_null() || capacity < 16 { return -2; }
    write_f64_le(output, 0, dx as f64 / d as f64);
    write_f64_le(output, 8, dy as f64 / d as f64);
    2
}
