/// Hash a bounded ASCII codepoint array with the Python ELF recurrence.
const MAX_CODEPOINTS: usize = 8;

#[no_mangle]
pub unsafe extern "C" fn elf_hash(input: *const i64, length: usize) -> i64 {
    if length > MAX_CODEPOINTS || (input.is_null() && length != 0) { return -1; }

    let mut hash = 0u64;
    for index in 0..length {
        let codepoint = *input.add(index);
        if !(0..=127).contains(&codepoint) { return -1; }
        hash = (hash << 4) + codepoint as u64;
        let high = hash & 0xF0000000;
        if high != 0 { hash ^= high >> 24; }
        hash ^= high;
    }
    hash as i64
}
