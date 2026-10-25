// Independent ROP3 truth-table dependency profile; full AFPL v5 is bundled.
#[no_mangle]
pub unsafe extern "C" fn cbench_ghostscript_rop3_operand_usage(values: *const i64, length: usize) -> i64 {
    if length > 2 || (length != 0 && values.is_null()) || length != 1 { return -1; }
    let value = unsafe { *values };
    if !(0..=255).contains(&value) { return -1; }
    let code = value as u64;
    let mut usage = 0u64;
    for dimension in 0..3 {
        let toggle = 1u64 << dimension;
        for index in 0..8 {
            if index & toggle == 0 && ((code >> index) & 1) != ((code >> (index | toggle)) & 1) {
                usage |= toggle;
                break;
            }
        }
    }
    usage as i64
}
