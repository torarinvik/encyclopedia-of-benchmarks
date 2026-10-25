// Independent bounded ROP3 profile. See package README and full AFPL v5
// license in benchmarks/g/cbench_ghostscript_rop3/LICENSE.txt.
#[no_mangle]
pub unsafe extern "C" fn cbench_ghostscript_rop3(values: *const i64, length: usize) -> i64 {
    if length > 5 || (length != 0 && values.is_null()) || length != 4 { return -1; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    if input[..3].iter().any(|&v| !(0..=4_294_967_295).contains(&v)) || !(0..=255).contains(&input[3]) { return -1; }
    let (d, s, t, code) = (input[0] as u64, input[1] as u64, input[2] as u64, input[3] as u64);
    let mut result = 0u64;
    for bit in 0..32 {
        let index = (((t >> bit) & 1) << 2) | (((s >> bit) & 1) << 1) | ((d >> bit) & 1);
        if ((code >> index) & 1) != 0 { result |= 1u64 << bit; }
    }
    result as i64
}
