const MAX_PAIRS: usize = 10;
const MAX_INPUT_LENGTH: usize = 22;
const WAYS_STRIDE: usize = 11;
const WAYS_COUNT: usize = 231;

#[no_mangle]
pub unsafe extern "C" fn balanced_parenthesis_rank_unrank(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let mode = values[0];
    let pairs_value = values[1];
    if pairs_value < 1 || pairs_value > MAX_PAIRS as i64 { return -1; }
    let pairs = pairs_value as usize;
    let sequence_length = 2 * pairs;
    if mode == 0 {
        if length != 2 + sequence_length { return -1; }
        let mut balance = 0i32;
        for i in 0..sequence_length {
            let symbol = values[2 + i];
            if symbol != 0 && symbol != 1 { return -1; }
            balance += if symbol == 0 { 1 } else { -1 };
            if balance < 0 { return -1; }
        }
        if balance != 0 { return -1; }
    } else if mode == 1 {
        if length != 3 { return -1; }
    } else {
        return -1;
    }

    let mut ways = [0i64; WAYS_COUNT];
    ways[0] = 1;
    for remaining in 1..=sequence_length {
        for balance in 0..=pairs {
            let mut count = 0i64;
            if balance < pairs { count += ways[(remaining - 1) * WAYS_STRIDE + balance + 1]; }
            if balance > 0 { count += ways[(remaining - 1) * WAYS_STRIDE + balance - 1]; }
            ways[remaining * WAYS_STRIDE + balance] = count;
        }
    }

    if mode == 0 {
        let mut rank = 0i64;
        let mut balance = 0usize;
        for i in 0..sequence_length {
            let symbol = values[2 + i];
            let remaining = sequence_length - i - 1;
            if symbol == 1 && balance < pairs {
                rank += ways[remaining * WAYS_STRIDE + balance + 1];
            }
            if symbol == 0 { balance += 1; } else { balance -= 1; }
        }
        return rank;
    }

    let mut rank = values[2];
    if rank < 0 || rank >= ways[sequence_length * WAYS_STRIDE] { return -1; }
    let mut balance = 0usize;
    let mut code = 0u64;
    for i in 0..sequence_length {
        let remaining = sequence_length - i - 1;
        let opening_count = if balance < pairs { ways[remaining * WAYS_STRIDE + balance + 1] } else { 0 };
        let symbol: u64;
        if rank < opening_count {
            symbol = 0;
            balance += 1;
        } else {
            rank -= opening_count;
            symbol = 1;
            balance -= 1;
        }
        code = (code << 1) | symbol;
    }
    code as i64
}
