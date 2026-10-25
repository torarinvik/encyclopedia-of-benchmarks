// Independent ROP3 truth-table transforms; full AFPL v5 is bundled.
#[no_mangle]
pub unsafe extern "C" fn cbench_ghostscript_rop3_transform(values: *const i64, length: usize) -> i64 {
    if length > 3 || (length != 0 && values.is_null()) || length != 2 { return -1; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    if !(0..=14).contains(&input[0]) || !(0..=255).contains(&input[1]) { return -1; }
    let mode = input[0] as usize;
    let code = input[1] as u64;
    let mut result = 0u64;
    for index in 0usize..8 {
        let d = index & 1;
        let s = (index >> 1) & 1;
        let t = (index >> 2) & 1;
        let mut source_index = index;
        let mut forced: Option<u64> = None;
        if mode <= 2 { source_index ^= 1usize << mode; }
        else if mode <= 8 {
            let dimension = (mode - 3) / 2;
            let pinned = (mode - 3) & 1;
            source_index = (index & !(1usize << dimension)) | (pinned << dimension);
        } else if mode == 9 { source_index = (index & !6usize) | (s << 2) | (t << 1); }
        else if mode <= 13 {
            let operand = if mode < 12 { s } else { t };
            if operand == ((mode - 10) & 1) { forced = Some(d as u64); }
        } else { forced = Some(1 - ((code >> index) & 1)); }
        let bit = forced.unwrap_or((code >> source_index) & 1);
        result |= bit << index;
    }
    result as i64
}
