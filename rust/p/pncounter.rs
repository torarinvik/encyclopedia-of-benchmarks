const MAX_NODES: usize = 16;
const MAX_OPERATIONS: usize = 64;
const MAX_INPUT_LENGTH: usize = 5 + MAX_OPERATIONS;
const MAX_OUTPUT_WORDS: usize = 2 * MAX_OPERATIONS;
const PAIRS: [(usize, usize); 6] = [(0, 1), (0, 2), (1, 0), (1, 2), (2, 0), (2, 1)];

fn append(words: &mut [i64; MAX_OUTPUT_WORDS], count: &mut usize, value: i64) {
    words[*count] = value;
    *count += 1;
}

#[no_mangle]
pub unsafe extern "C" fn pncounter(input: *const i64, length: usize,
                                     output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || !(5..=MAX_INPUT_LENGTH).contains(&length) { return -1; }
    let input = std::slice::from_raw_parts(input, length);
    if !(1..=MAX_NODES as i64).contains(&input[0]) ||
        !(0..=MAX_OPERATIONS as i64).contains(&input[4]) { return -1; }

    let node_count = input[0] as usize;
    let mut ids = [0usize; 3];
    for counter in 0..3 {
        if input[1 + counter] < 0 || input[1 + counter] >= input[0] { return -1; }
        ids[counter] = input[1 + counter] as usize;
    }
    let operation_count = input[4] as usize;
    if length != 5 + operation_count { return -1; }

    let mut positive = [[0i64; MAX_NODES]; 3];
    let mut negative = [[0i64; MAX_NODES]; 3];
    let mut words = [0i64; MAX_OUTPUT_WORDS];
    let mut word_count = 0usize;
    let mut position = 5usize;

    for _ in 0..operation_count {
        let opcode = input[position];
        position += 1;
        if !(0..=20).contains(&opcode) { return -1; }
        if opcode < 6 {
            let counter = (opcode / 2) as usize;
            if opcode % 2 == 0 { positive[counter][ids[counter]] += 1; }
            else { negative[counter][ids[counter]] += 1; }
            append(&mut words, &mut word_count, opcode);
        } else if opcode < 9 {
            let counter = (opcode - 6) as usize;
            let mut value = 0i64;
            for node in 0..node_count { value += positive[counter][node] - negative[counter][node]; }
            append(&mut words, &mut word_count, opcode);
            append(&mut words, &mut word_count, value);
        } else if opcode < 15 {
            let (target, source) = PAIRS[(opcode - 9) as usize];
            for node in 0..node_count {
                positive[target][node] = positive[target][node].max(positive[source][node]);
                negative[target][node] = negative[target][node].max(negative[source][node]);
            }
            append(&mut words, &mut word_count, opcode);
        } else {
            let (left, right) = PAIRS[(opcode - 15) as usize];
            let result = !(0..node_count).any(|node| {
                positive[left][node] > positive[right][node] &&
                    negative[left][node] > negative[right][node]
            });
            append(&mut words, &mut word_count, opcode);
            append(&mut words, &mut word_count, if result { 1 } else { 0 });
        }
    }

    let output_length = word_count * 8;
    if output.is_null() || output_capacity < output_length { return -2; }
    for (i, word) in words[..word_count].iter().enumerate() {
        let bytes = word.to_le_bytes();
        std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(i * 8), 8);
    }
    output_length as i64
}
