const MAX_PATTERN: usize = 6;
const MAX_VARIABLES: usize = 12;
const MAX_FACTORS: usize = 8;
const MAX_TEXT: usize = 64;
const MAX_INPUT: usize = 53;
const MAX_OUTPUT_BYTES: usize = 520;

#[no_mangle]
pub unsafe extern "C" fn kmp_slp_jump_output(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 8 || length > MAX_INPUT { return -1; }
    let mut cursor = 0usize;
    let pattern_raw = *input.add(cursor); cursor += 1;
    if pattern_raw < 1 || pattern_raw > MAX_PATTERN as i64 { return -1; }
    let pattern_length = pattern_raw as usize;
    let mut pattern = [0i64; MAX_PATTERN];
    for i in 0..pattern_length { pattern[i] = *input.add(cursor); cursor += 1; if pattern[i] < 0 || pattern[i] > 3 { return -1; } }
    if cursor >= length { return -1; }
    let variable_raw = *input.add(cursor); cursor += 1;
    if variable_raw < 1 || variable_raw > MAX_VARIABLES as i64 || cursor + 3 * variable_raw as usize + 1 > length { return -1; }
    let variable_count = variable_raw as usize;
    let mut kind = [0usize; MAX_VARIABLES];
    let mut first = [0usize; MAX_VARIABLES];
    let mut second = [0usize; MAX_VARIABLES];
    let mut terminal = [0i64; MAX_VARIABLES];
    let mut variable_length = [0usize; MAX_VARIABLES];
    for variable in 0..variable_count {
        let kind_raw = *input.add(cursor); let first_raw = *input.add(cursor + 1); let second_raw = *input.add(cursor + 2); cursor += 3;
        if kind_raw == 0 {
            if first_raw < 0 || first_raw > 3 || second_raw != 0 { return -1; }
            terminal[variable] = first_raw; variable_length[variable] = 1;
        } else if kind_raw == 1 {
            if first_raw < 0 || second_raw < 0 || first_raw >= variable as i64 || second_raw >= variable as i64 { return -1; }
            kind[variable] = 1; first[variable] = first_raw as usize; second[variable] = second_raw as usize;
            variable_length[variable] = variable_length[first[variable]] + variable_length[second[variable]];
            if variable_length[variable] > MAX_TEXT { return -1; }
        } else { return -1; }
    }
    if cursor >= length { return -1; }
    let factor_raw = *input.add(cursor); cursor += 1;
    if factor_raw < 1 || factor_raw > MAX_FACTORS as i64 || cursor + factor_raw as usize != length { return -1; }
    let factor_count = factor_raw as usize;
    let mut factors = [0usize; MAX_FACTORS];
    let mut text_length = 0usize;
    for i in 0..factor_count {
        let factor = *input.add(cursor); cursor += 1;
        if factor < 0 || factor >= variable_raw { return -1; }
        factors[i] = factor as usize; text_length += variable_length[factors[i]];
        if text_length > MAX_TEXT { return -1; }
    }
    let mut failure = [0usize; MAX_PATTERN];
    let mut border = 0usize;
    for i in 1..pattern_length {
        while border > 0 && pattern[i] != pattern[border] { border = failure[border - 1]; }
        if pattern[i] == pattern[border] { border += 1; }
        failure[i] = border;
    }
    let mut jump = [[0usize; MAX_PATTERN]; MAX_VARIABLES];
    let mut output_mask = [[0u64; MAX_PATTERN]; MAX_VARIABLES];
    for variable in 0..variable_count { for state in 0..pattern_length {
        if kind[variable] == 0 {
            let mut next = state;
            while next > 0 && pattern[next] != terminal[variable] { next = failure[next - 1]; }
            if pattern[next] == terminal[variable] { next += 1; }
            if next == pattern_length { output_mask[variable][state] = 1; next = failure[pattern_length - 1]; }
            jump[variable][state] = next;
        } else {
            let left = first[variable]; let right = second[variable]; let middle = jump[left][state];
            jump[variable][state] = jump[right][middle];
            output_mask[variable][state] = output_mask[left][state] | (output_mask[right][middle] << variable_length[left]);
        }
    }}
    let mut state = 0usize; let mut offset = 0usize; let mut end_offsets = 0u64;
    for i in 0..factor_count { let variable = factors[i]; end_offsets |= output_mask[variable][state] << offset; state = jump[variable][state]; offset += variable_length[variable]; }
    let mut words = [0i64; 1 + MAX_TEXT]; let mut occurrences = 0usize;
    for end in 0..text_length { if ((end_offsets >> end) & 1) != 0 {
        if end + 1 < pattern_length { return -1; }
        words[1 + occurrences] = (end + 1 - pattern_length) as i64; occurrences += 1;
    }}
    words[0] = occurrences as i64;
    let output_bytes = 8 * (1 + occurrences);
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut staged = [0u8; MAX_OUTPUT_BYTES];
    for word in 0..1 + occurrences { let bytes = words[word].to_le_bytes(); std::ptr::copy_nonoverlapping(bytes.as_ptr(), staged.as_mut_ptr().add(8 * word), 8); }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, output_bytes);
    output_bytes as i64
}
