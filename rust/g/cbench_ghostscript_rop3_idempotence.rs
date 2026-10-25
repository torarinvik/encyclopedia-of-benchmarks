// Independent bounded profile; full Aladdin Free Public License v5 is bundled.
#[no_mangle]
pub unsafe extern "C" fn cbench_ghostscript_rop3_idempotence(values: *const i64, length: usize) -> i64 {
    if length > 2 || (length != 0 && values.is_null()) || length != 1 { return -1; }
    let code = unsafe { *values };
    if !(0..=255).contains(&code) { return -1; }
    let code = code as u64;
    for bit in (1..8).step_by(2) {
        if ((code >> bit) & 1) != 0 && ((code >> (bit - 1)) & 1) == 0 { return 0; }
    }
    1
}
