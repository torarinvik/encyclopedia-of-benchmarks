const MAX_INPUT_BYTES: usize = 256;
const MAX_TOKEN_BYTES: usize = 45;
const MAX_UNIQUE_WORDS: usize = 128;
const MAX_OUTPUT_BYTES: usize = 896;

#[derive(Clone, Copy)]
struct WordNode {
    word: [u8; MAX_TOKEN_BYTES + 1],
    word_length: usize,
    frequency: u64,
    left: i32,
    right: i32,
}

impl WordNode {
    const EMPTY: Self = Self {
        word: [0; MAX_TOKEN_BYTES + 1],
        word_length: 0,
        frequency: 0,
        left: -1,
        right: -1,
    };
}

fn ascii_alpha(value: i64) -> bool {
    (65..=90).contains(&value) || (97..=122).contains(&value)
}

#[no_mangle]
pub unsafe extern "C" fn word_frequency_bst(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_BYTES + 2 { return -1; }
    let n_value = *input;
    if n_value < 0 || n_value > MAX_INPUT_BYTES as i64 { return -1; }
    let text_length = n_value as usize;
    if length != text_length + 1 { return -1; }
    for i in 0..text_length {
        let value = *input.add(i + 1);
        if !(0..=127).contains(&value) { return -1; }
    }

    let mut nodes = [WordNode::EMPTY; MAX_UNIQUE_WORDS];
    let mut used = 0usize;
    let mut root = -1i32;
    let mut token = [0u8; MAX_TOKEN_BYTES + 1];
    let mut token_length = 0usize;
    for position in 0..=text_length {
        let byte = if position < text_length { *input.add(position + 1) } else { -1 };
        if ascii_alpha(byte) {
            if token_length >= MAX_TOKEN_BYTES { return -1; }
            token[token_length] = if (65..=90).contains(&byte) { (byte + 32) as u8 } else { byte as u8 };
            token_length += 1;
        } else if (byte == 39 || byte == 45) && token_length > 0 && ascii_alpha(token[token_length - 1] as i64) {
            if token_length >= MAX_TOKEN_BYTES { return -1; }
            token[token_length] = byte as u8;
            token_length += 1;
        } else {
            if token_length > 0 {
                if token[token_length - 1] == b'-' { token_length -= 1; }
                if token_length > 0 {
                    if root < 0 {
                        if used >= MAX_UNIQUE_WORDS { return -1; }
                        root = used as i32;
                        nodes[used].word[..token_length].copy_from_slice(&token[..token_length]);
                        nodes[used].word[token_length] = 0;
                        nodes[used].word_length = token_length;
                        nodes[used].frequency = 1;
                        used += 1;
                    } else {
                        let mut current = root as usize;
                        loop {
                            let node_length = nodes[current].word_length;
                            let common = token_length.min(node_length);
                            let mut order = 0i32;
                            for j in 0..common {
                                if token[j] < nodes[current].word[j] { order = -1; break; }
                                if token[j] > nodes[current].word[j] { order = 1; break; }
                            }
                            if order == 0 {
                                if token_length < node_length { order = -1; }
                                else if token_length > node_length { order = 1; }
                            }
                            if order == 0 {
                                nodes[current].frequency += 1;
                                break;
                            }
                            let child = if order < 0 { nodes[current].left } else { nodes[current].right };
                            if child < 0 {
                                if used >= MAX_UNIQUE_WORDS { return -1; }
                                let new_node = used;
                                nodes[new_node].word[..token_length].copy_from_slice(&token[..token_length]);
                                nodes[new_node].word[token_length] = 0;
                                nodes[new_node].word_length = token_length;
                                nodes[new_node].frequency = 1;
                                if order < 0 { nodes[current].left = new_node as i32; }
                                else { nodes[current].right = new_node as i32; }
                                used += 1;
                                break;
                            }
                            current = child as usize;
                        }
                    }
                }
                token_length = 0;
            }
        }
    }

    let mut result = [0u8; MAX_OUTPUT_BYTES];
    let mut stack = [0i32; MAX_UNIQUE_WORDS];
    let (mut top, mut written) = (0usize, 0usize);
    let mut current = root;
    while current >= 0 || top > 0 {
        while current >= 0 {
            if top >= MAX_UNIQUE_WORDS { return -1; }
            stack[top] = current;
            top += 1;
            current = nodes[current as usize].left;
        }
        top -= 1;
        current = stack[top];
        let node = &nodes[current as usize];
        for &byte in &node.word[..node.word_length] {
            if written >= MAX_OUTPUT_BYTES { return -1; }
            result[written] = byte;
            written += 1;
        }
        if written + 1 >= MAX_OUTPUT_BYTES { return -1; }
        result[written] = b'\t';
        written += 1;
        let mut reversed = [0u8; 20];
        let mut digits = 0usize;
        let mut frequency = node.frequency;
        loop {
            reversed[digits] = b'0' + (frequency % 10) as u8;
            digits += 1;
            frequency /= 10;
            if frequency == 0 { break; }
        }
        while digits > 0 {
            digits -= 1;
            if written >= MAX_OUTPUT_BYTES { return -1; }
            result[written] = reversed[digits];
            written += 1;
        }
        if written >= MAX_OUTPUT_BYTES { return -1; }
        result[written] = b'\n';
        written += 1;
        current = nodes[current as usize].right;
    }

    if output.is_null() || capacity < written { return -2; }
    std::ptr::copy_nonoverlapping(result.as_ptr(), output, written);
    written as i64
}
