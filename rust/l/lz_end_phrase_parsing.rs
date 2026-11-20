const MAX_TEXT: usize = 64;
const MAX_INPUT: usize = 66;
const PHRASE_MULTIPLIER: i64 = 133_121;

#[no_mangle]
pub unsafe extern "C" fn lz_end_phrase_parsing(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT { return -1; }
    let n64 = *input;
    if n64 < 0 || n64 > MAX_TEXT as i64 || length != n64 as usize + 1 { return -1; }
    let n = n64 as usize;
    let values = std::slice::from_raw_parts(input, length);
    if values[1..].iter().any(|&value| !(0..=255).contains(&value)) { return -1; }
    let mut boundaries = [0usize; MAX_TEXT];
    let mut phrase_lengths = [0usize; MAX_TEXT];
    let mut phrases = 0usize;
    let mut position = 0usize;
    while position < n {
        let mut best_copy = 0usize;
        let mut copy_length = n - position - 1;
        while copy_length > 0 && best_copy == 0 {
            let mut prior = phrases;
            while prior > 0 && best_copy == 0 {
                prior -= 1;
                let boundary = boundaries[prior];
                if boundary < copy_length { continue; }
                let mut matches = true;
                for offset in 0..copy_length {
                    if values[1 + position + offset] != values[1 + boundary - copy_length + offset] {
                        matches = false;
                        break;
                    }
                }
                if matches { best_copy = copy_length; }
            }
            copy_length -= 1;
        }
        phrase_lengths[phrases] = best_copy + 1;
        position += phrase_lengths[phrases];
        boundaries[phrases] = position;
        phrases += 1;
    }
    let mut checksum = 0i64;
    for i in 0..phrases { checksum += (i as i64 + 1) * phrase_lengths[i] as i64; }
    PHRASE_MULTIPLIER * phrases as i64 + checksum
}
