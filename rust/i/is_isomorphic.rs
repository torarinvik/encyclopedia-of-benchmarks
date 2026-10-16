/// Check whether two bounded ASCII strings preserve a one-to-one mapping.
const MAX_CODEPOINTS: usize = 8;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_CODEPOINTS + 2;

#[no_mangle]
pub unsafe extern "C" fn is_isomorphic(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let source_length = *input;
    let target_length = *input.add(1);
    if !(0..=MAX_CODEPOINTS as i64).contains(&source_length) ||
        !(0..=MAX_CODEPOINTS as i64).contains(&target_length) { return -1; }
    let source_count = source_length as usize;
    let target_count = target_length as usize;
    if length != 2 + source_count + target_count { return -1; }
    for index in 2..length {
        let codepoint = *input.add(index);
        if !(0..=127).contains(&codepoint) { return -1; }
    }
    if source_count != target_count { return 0; }

    let mut source_to_target = [-1i64; 128];
    let mut target_to_source = [-1i64; 128];
    for index in 0..source_count {
        let source = *input.add(2 + index) as usize;
        let target = *input.add(2 + source_count + index) as usize;
        if (source_to_target[source] != -1 && source_to_target[source] != target as i64) ||
            (target_to_source[target] != -1 && target_to_source[target] != source as i64) { return 0; }
        source_to_target[source] = target as i64;
        target_to_source[target] = source as i64;
    }
    1
}
