/// Count equal-value index pairs with a bounded open-addressed frequency table.
const MAX_ARRAY_LENGTH: i64 = 256;
const MAX_INPUT_LENGTH: usize = 258;
const TABLE_SIZE: usize = 512;

#[no_mangle]
pub unsafe extern "C" fn good_pairs_hash(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let declared = *input;
    if declared < 0 || declared > MAX_ARRAY_LENGTH || length != declared as usize + 1 { return -1; }
    let n = declared as usize;
    let mut keys = [0i64; TABLE_SIZE];
    let mut frequencies = [0u64; TABLE_SIZE];
    let mut occupied = [false; TABLE_SIZE];
    for index in 0..n {
        let value = *input.add(index + 1);
        if !(-1_000_000..=1_000_000).contains(&value) { return -1; }
        let mut slot = (((value + 1_000_000) * 2_654_435_761) as usize) & (TABLE_SIZE - 1);
        while occupied[slot] && keys[slot] != value { slot = (slot + 1) & (TABLE_SIZE - 1); }
        if !occupied[slot] { occupied[slot] = true; keys[slot] = value; }
        frequencies[slot] += 1;
    }
    let mut pairs = 0u64;
    for frequency in frequencies {
        if frequency > 1 { pairs += frequency * (frequency - 1) / 2; }
    }
    pairs as i64
}
