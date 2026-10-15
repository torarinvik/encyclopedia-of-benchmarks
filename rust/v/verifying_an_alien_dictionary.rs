const MAX_WORDS: usize = 100;
const INVALID_RESULT: i64 = -1;

#[no_mangle]
pub unsafe extern "C" fn verifying_an_alien_dictionary(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 27 || length > 2127 { return INVALID_RESULT; }
    let word_count_arg = *input;
    if !(1..=MAX_WORDS as i64).contains(&word_count_arg) { return INVALID_RESULT; }
    let word_count = word_count_arg as usize;
    let mut rank = [0i64; 26];
    let mut order_seen = [false; 26];
    for position in 0..26 {
        let letter = *input.add(1 + position);
        if !(b'a' as i64..=b'z' as i64).contains(&letter) { return INVALID_RESULT; }
        let index = (letter - b'a' as i64) as usize;
        if order_seen[index] { return INVALID_RESULT; }
        order_seen[index] = true;
        rank[index] = position as i64;
    }

    let mut starts = [0usize; MAX_WORDS];
    let mut word_lengths = [0usize; MAX_WORDS];
    let mut offset = 27usize;
    for word in 0..word_count {
        if offset >= length { return INVALID_RESULT; }
        let word_length_arg = *input.add(offset);
        if !(1..=20).contains(&word_length_arg) { return INVALID_RESULT; }
        let word_length = word_length_arg as usize;
        offset += 1;
        if word_length > length - offset { return INVALID_RESULT; }
        starts[word] = offset;
        word_lengths[word] = word_length;
        for character in 0..word_length {
            let letter = *input.add(offset + character);
            if !(b'a' as i64..=b'z' as i64).contains(&letter) { return INVALID_RESULT; }
        }
        offset += word_length;
    }
    if offset != length { return INVALID_RESULT; }

    for word in 0..word_count.saturating_sub(1) {
        let left_length = word_lengths[word];
        let right_length = word_lengths[word + 1];
        let limit = left_length.min(right_length);
        let mut decided = false;
        for character in 0..limit {
            let left_letter = (*input.add(starts[word] + character) - b'a' as i64) as usize;
            let right_letter = (*input.add(starts[word + 1] + character) - b'a' as i64) as usize;
            if rank[left_letter] < rank[right_letter] {
                decided = true;
                break;
            }
            if rank[left_letter] > rank[right_letter] { return 0; }
        }
        if !decided && left_length > right_length { return 0; }
    }
    1
}
