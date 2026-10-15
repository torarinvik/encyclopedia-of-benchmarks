const MAX_WORD_LENGTH: usize = 16;
const MAX_CANDIDATES: usize = 16;

fn is_letter(value: i64) -> bool { (65..=90).contains(&value) || (97..=122).contains(&value) }
fn lower_index(value: i64) -> usize { if (65..=90).contains(&value) { (value - 65) as usize } else { (value - 97) as usize } }

#[no_mangle]
pub unsafe extern "C" fn detect_anagrams(input: *const i64, length: usize,
                                           output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 0 || values[0] > MAX_WORD_LENGTH as i64 { return -1; }
    let subject_length = values[0] as usize;
    let mut offset = 1 + subject_length;
    if offset >= length || values[1..1 + subject_length].iter().any(|&c| !is_letter(c)) { return -1; }
    if values[offset] < 0 || values[offset] > MAX_CANDIDATES as i64 { return -1; }
    let candidate_count = values[offset] as usize; offset += 1;
    let mut subject_counts = [0i32; 26];
    for &value in &values[1..1 + subject_length] { subject_counts[lower_index(value)] += 1; }
    if output.is_null() { return -2; }
    let output = std::slice::from_raw_parts_mut(output, capacity);
    let mut output_length = 0usize;
    let mut matches = 0i64;
    for _ in 0..candidate_count {
        if offset >= length || values[offset] < 0 || values[offset] > MAX_WORD_LENGTH as i64 { return -1; }
        let word_length = values[offset] as usize; offset += 1;
        if offset + word_length > length || values[offset..offset + word_length].iter().any(|&c| !is_letter(c)) { return -1; }
        let mut counts = subject_counts;
        let mut identical = word_length == subject_length;
        for i in 0..word_length {
            let value = values[offset + i];
            counts[lower_index(value)] -= 1;
            if identical && lower_index(value) != lower_index(values[1 + i]) { identical = false; }
        }
        let same_counts = word_length == subject_length && counts.iter().all(|&count| count == 0);
        if same_counts && !identical {
            for &value in &values[offset..offset + word_length] {
                if output_length >= capacity { return -2; }
                output[output_length] = value as u8; output_length += 1;
            }
            if output_length >= capacity { return -2; }
            output[output_length] = b'\n'; output_length += 1;
            matches += 1;
        }
        offset += word_length;
    }
    if offset != length { return -1; }
    if output_length >= capacity { return -2; }
    output[output_length] = 0;
    matches
}
