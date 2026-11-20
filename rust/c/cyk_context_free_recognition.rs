const MAX_NONTERMINALS: i64 = 4;
const MAX_TERMINALS: i64 = 2;
const MAX_WORD_LENGTH: i64 = 8;
const MAX_PRODUCTIONS: i64 = 12;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 62;

#[no_mangle]
pub unsafe extern "C" fn cyk_context_free_recognition(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(5..=MAX_PARSEABLE_INPUT_LENGTH).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (variables_value, alphabet_value, word_value, rule_value, start_value) =
        (values[0], values[1], values[2], values[3], values[4]);
    if !(1..=MAX_NONTERMINALS).contains(&variables_value)
        || !(1..=MAX_TERMINALS).contains(&alphabet_value)
        || !(1..=MAX_WORD_LENGTH).contains(&word_value)
        || !(0..=MAX_PRODUCTIONS).contains(&rule_value)
        || start_value < 0 || start_value >= variables_value { return -1; }
    let word_length = word_value as usize;
    let rule_count = rule_value as usize;
    if length != 5 + word_length + 4 * rule_count { return -1; }
    for &token in &values[5..5 + word_length] {
        if token < 0 || token >= alphabet_value { return -1; }
    }
    let rules = 5 + word_length;
    for rule in 0..rule_count {
        let offset = rules + 4 * rule;
        let (kind, lhs, first, second) =
            (values[offset], values[offset + 1], values[offset + 2], values[offset + 3]);
        if lhs < 0 || lhs >= variables_value { return -1; }
        if kind == 0 {
            if first < 0 || first >= alphabet_value || second != 0 { return -1; }
        } else if kind == 1 {
            if first < 0 || first >= variables_value || second < 0 || second >= variables_value {
                return -1;
            }
        } else { return -1; }
    }

    let mut chart = [[[false; 9]; 8]; 4];
    for position in 0..word_length {
        let token = values[5 + position];
        for rule in 0..rule_count {
            let offset = rules + 4 * rule;
            if values[offset] == 0 && values[offset + 2] == token {
                chart[values[offset + 1] as usize][position][1] = true;
            }
        }
    }
    for width in 2..=word_length {
        for left in 0..=word_length - width {
            for rule in 0..rule_count {
                let offset = rules + 4 * rule;
                if values[offset] != 1 { continue; }
                let lhs = values[offset + 1] as usize;
                let first = values[offset + 2] as usize;
                let second = values[offset + 3] as usize;
                for split in 1..width {
                    if chart[first][left][split] && chart[second][left + split][width - split] {
                        chart[lhs][left][width] = true;
                        break;
                    }
                }
            }
        }
    }
    if chart[start_value as usize][0][word_length] { 1 } else { 0 }
}
