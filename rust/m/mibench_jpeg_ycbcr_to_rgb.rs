const MAX_PIXELS: usize = 16;
fn arshift16(x: i64) -> i64 { if x >= 0 { x / 65536 } else { -((-x + 65535) / 65536) } }
fn clamp8(x: i64) -> u8 { x.clamp(0, 255) as u8 }
unsafe fn put(out: *mut u8, bytes: &[u8]) { for (i, b) in bytes.iter().enumerate() { unsafe { *out.add(i) = *b; } } }

#[no_mangle]
pub unsafe extern "C" fn mibench_jpeg_ycbcr_to_rgb(v: *const i64, n: usize, out: *mut u8, cap: usize) -> i64 {
    if v.is_null() || !(4..=49).contains(&n) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(v, n) };
    if !(1..=MAX_PIXELS as i64).contains(&values[0]) || n != 1 + 3 * values[0] as usize { return -1; }
    if values[1..].iter().any(|x| !(0..=255).contains(x)) { return -1; }
    let mut staged = [0u8; 48]; let mut p = 0;
    for i in (1..n).step_by(3) {
        let y=values[i]; let cb=values[i+1]-128; let cr=values[i+2]-128;
        staged[p]=clamp8(y+arshift16(91881*cr+32768)); p+=1;
        staged[p]=clamp8(y+arshift16(-22554*cb+32768-46802*cr)); p+=1;
        staged[p]=clamp8(y+arshift16(116130*cb+32768)); p+=1;
    }
    if out.is_null() || cap < p { return -2; }
    unsafe { put(out, &staged[..p]); }
    p as i64
}
