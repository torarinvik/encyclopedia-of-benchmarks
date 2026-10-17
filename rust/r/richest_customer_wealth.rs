const MAX_ROWS: usize = 32;
const MAX_COLUMNS: usize = 32;
const MAX_INPUT_LENGTH: usize = 2 + MAX_ROWS * MAX_COLUMNS + 1;
const MAX_AMOUNT: i64 = 1_000_000;

#[no_mangle]
pub unsafe extern "C" fn richest_customer_wealth(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let values = core::slice::from_raw_parts(input, length);
    if !(1..=MAX_ROWS as i64).contains(&values[0]) || !(1..=MAX_COLUMNS as i64).contains(&values[1]) { return -1; }
    let rows = values[0] as usize;
    let columns = values[1] as usize;
    if length != 2 + rows * columns { return -1; }
    let mut richest = 0_i64;
    for row in 0..rows {
        let mut wealth = 0_i64;
        for column in 0..columns {
            let amount = values[2 + row * columns + column];
            if !(0..=MAX_AMOUNT).contains(&amount) { return -1; }
            wealth += amount;
        }
        if wealth > richest { richest = wealth; }
    }
    richest
}
