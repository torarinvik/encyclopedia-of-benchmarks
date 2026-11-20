const MAX_RULES: usize = 8;
const MAX_STEPS: usize = 32;
const MAX_WORD: usize = 64;

#[derive(Clone, Copy)]
struct Rule {
    kind: i64,
    left_len: usize,
    right_len: usize,
    left: [i64; 8],
    right: [i64; 8],
}

impl Default for Rule {
    fn default() -> Self {
        Self { kind: 0, left_len: 0, right_len: 0, left: [0; 8], right: [0; 8] }
    }
}

#[no_mangle]
pub unsafe extern "C" fn markov_normal_string_rewriting(
    input_ptr: *const i64, length: usize, output_ptr: *mut u8, capacity: usize,
) -> i64 {
    if input_ptr.is_null() || !(3..=204).contains(&length) { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input_ptr, length) };
    if !(0..=MAX_RULES as i64).contains(&input[0])
        || !(0..=MAX_STEPS as i64).contains(&input[1])
        || !(0..=48).contains(&input[2]) { return -1; }
    let count = input[0] as usize;
    let budget = input[1] as usize;
    let initial = input[2] as usize;
    if length < 3 + initial { return -1; }
    let mut word = [0i64; MAX_WORD];
    let mut word_len = initial;
    let mut cursor = 3;
    for slot in word.iter_mut().take(initial) {
        if !(0..=25).contains(&input[cursor]) { return -1; }
        *slot = input[cursor];
        cursor += 1;
    }
    let mut rules = [Rule::default(); MAX_RULES];
    for rule in rules.iter_mut().take(count) {
        if cursor + 3 > length { return -1; }
        let kind = input[cursor];
        let left_len = input[cursor + 1];
        let right_len = input[cursor + 2];
        cursor += 3;
        if !(0..=1).contains(&kind) || !(1..=8).contains(&left_len) || !(0..=8).contains(&right_len) { return -1; }
        rule.kind = kind;
        rule.left_len = left_len as usize;
        rule.right_len = right_len as usize;
        if cursor + rule.left_len + rule.right_len > length { return -1; }
        for i in 0..rule.left_len {
            if !(0..=25).contains(&input[cursor]) { return -1; }
            rule.left[i] = input[cursor];
            cursor += 1;
        }
        for i in 0..rule.right_len {
            if !(0..=25).contains(&input[cursor]) { return -1; }
            rule.right[i] = input[cursor];
            cursor += 1;
        }
    }
    if cursor != length { return -1; }

    let mut rewrites = 0usize;
    let mut halt = 0u8;
    loop {
        let mut match_at = None;
        'priority: for (r, rule) in rules.iter().take(count).enumerate() {
            if rule.left_len > word_len { continue; }
            for offset in 0..=word_len - rule.left_len {
                if word[offset..offset + rule.left_len] == rule.left[..rule.left_len] {
                    match_at = Some((r, offset));
                    break 'priority;
                }
            }
        }
        let Some((rule_index, offset)) = match_at else { halt = 0; break; };
        if rewrites == budget { halt = 2; break; }
        let rule = rules[rule_index];
        let new_len = word_len - rule.left_len + rule.right_len;
        if new_len > MAX_WORD { return -3; }
        let mut next = [0i64; MAX_WORD];
        next[..offset].copy_from_slice(&word[..offset]);
        next[offset..offset + rule.right_len].copy_from_slice(&rule.right[..rule.right_len]);
        let suffix = offset + rule.left_len;
        let tail_len = word_len - suffix;
        next[offset + rule.right_len..new_len].copy_from_slice(&word[suffix..suffix + tail_len]);
        word = next;
        word_len = new_len;
        rewrites += 1;
        if rule.kind == 1 { halt = 1; break; }
    }

    let required = 3 + word_len;
    if output_ptr.is_null() || capacity < required { return -2; }
    let output = unsafe { std::slice::from_raw_parts_mut(output_ptr, required) };
    output[0] = halt;
    output[1] = rewrites as u8;
    output[2] = word_len as u8;
    for i in 0..word_len { output[3 + i] = word[i] as u8; }
    required as i64
}
