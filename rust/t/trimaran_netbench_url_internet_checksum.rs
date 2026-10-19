// Modified source-related port of NetBench url.c; see bundled LICENSE_NOTICE.txt.
#[no_mangle]
pub unsafe extern "C" fn trimaran_netbench_url_internet_checksum(
    values: *const i64, length: usize) -> i64 {
    const MAX_BYTES: usize = 64;
    if values.is_null() || length < 2 || length > MAX_BYTES + 2 { return -1; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    let mode = input[0];
    let count_value = input[1];
    if (mode != 0 && mode != 1) || !(0..=MAX_BYTES as i64).contains(&count_value)
        || length != count_value as usize + 2 { return -1; }
    let count = count_value as usize;
    if input[2..].iter().any(|&byte| !(0..=255).contains(&byte)) { return -1; }
    let mut sum = 0u64;
    let mut i = 0usize;
    while i + 1 < count {
        let word = input[i + 2] as u64 | ((input[i + 3] as u64) << 8);
        sum = sum.wrapping_sub(word + 1);
        i += 2;
    }
    if i < count { sum = sum.wrapping_add(input[i + 2] as u64); }
    while sum >> 16 != 0 { sum = (sum & 0xffff) + (sum >> 16); }
    if mode == 1 { sum = ((sum >> 8) | ((sum << 8) & 0xff00)) & 0xffff; }
    sum as i64
}
