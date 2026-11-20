const MAX_WORDS: usize = 16;
const MAX_QUERIES: usize = 8;
const MAX_WORD_LENGTH: usize = 10;
const MAX_RADIUS: i64 = 3;

fn valid_word(word: i64) -> bool {
    if word < 0 || ((word as u64) >> 44) != 0 {
        return false;
    }
    let packed = word as u64;
    let length = ((packed >> 40) & 15) as usize;
    if length > MAX_WORD_LENGTH {
        return false;
    }
    for position in 0..MAX_WORD_LENGTH {
        let symbol = (packed >> (4 * position)) & 15;
        if (position < length && symbol == 0) || (position >= length && symbol != 0) {
            return false;
        }
    }
    true
}

fn edit_distance(left: i64, right: i64) -> usize {
    let a = left as u64;
    let b = right as u64;
    let n = ((a >> 40) & 15) as usize;
    let m = ((b >> 40) & 15) as usize;
    let mut previous = [0usize; MAX_WORD_LENGTH + 1];
    let mut current = [0usize; MAX_WORD_LENGTH + 1];
    for j in 0..=m { previous[j] = j; }
    for i in 1..=n {
        current[0] = i;
        let a_symbol = (a >> (4 * (i - 1))) & 15;
        for j in 1..=m {
            let b_symbol = (b >> (4 * (j - 1))) & 15;
            let replace_cost = if a_symbol == b_symbol { 0 } else { 1 };
            let replace = previous[j - 1] + replace_cost;
            current[j] = (previous[j] + 1).min((current[j - 1] + 1).min(replace));
        }
        previous = current;
    }
    previous[m]
}

fn solve(values: &[i64]) -> i64 {
    if values.len() < 3 || values.len() > 28 {
        return -1;
    }
    let n_value = values[0];
    let q_value = values[1];
    let radius_value = values[2];
    if !(0..=MAX_WORDS as i64).contains(&n_value)
        || !(0..=MAX_QUERIES as i64).contains(&q_value)
        || !(0..=MAX_RADIUS).contains(&radius_value)
        || values.len() != 3 + n_value as usize + q_value as usize
    {
        return -1;
    }
    let n = n_value as usize;
    let q = q_value as usize;
    let radius = radius_value as usize;
    let words = &values[3..3 + n];
    let queries = &values[3 + n..];
    if values[3..].iter().any(|&word| !valid_word(word)) {
        return -1;
    }
    for i in 0..n {
        if words[..i].contains(&words[i]) { return -1; }
    }

    let mut children = [[-1i32; MAX_WORD_LENGTH + 1]; MAX_WORDS];
    for node in 1..n {
        let mut pivot = 0usize;
        loop {
            let edge = edit_distance(words[node], words[pivot]);
            let child = children[pivot][edge];
            if child == -1 {
                children[pivot][edge] = node as i32;
                break;
            }
            pivot = child as usize;
        }
    }

    let mut result = 0i64;
    for (query_index, &query) in queries.iter().enumerate() {
        let mut matches = 0i64;
        let mut index_sum = 0i64;
        if n != 0 {
            let mut stack = [0usize; MAX_WORDS];
            let mut top = 1usize;
            stack[0] = 0;
            while top != 0 {
                top -= 1;
                let node = stack[top];
                let distance = edit_distance(query, words[node]);
                if distance <= radius {
                    matches += 1;
                    index_sum += node as i64;
                }
                let low = distance.saturating_sub(radius);
                let high = (distance + radius).min(MAX_WORD_LENGTH);
                for edge in low..=high {
                    let child = children[node][edge];
                    if child >= 0 {
                        stack[top] = child as usize;
                        top += 1;
                    }
                }
            }
        }
        result += (query_index as i64 + 1) * (17 * matches + index_sum);
    }
    result
}

#[no_mangle]
pub unsafe extern "C" fn bk_tree_edit_distance_search(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > 28 {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    solve(values)
}
