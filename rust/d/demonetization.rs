/// Count denomination combinations with the source's recursive recurrence.
const MAX_AMOUNT: i64 = 30;
const MAX_DENOMINATIONS: i64 = 4;

fn ways(amount: i64, input: *const i64, count: i64) -> i64 {
    if amount < 0 || count < 0 { return 0; }
    if amount == 0 { return 1; }
    if count == 0 { return 0; }
    let denomination = unsafe { *input.add((count + 1) as usize) };
    ways(amount, input, count - 1) + ways(amount - denomination, input, count)
}

#[no_mangle]
pub extern "C" fn demonetization(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > (MAX_DENOMINATIONS + 2) as usize { return -1; }
    let amount = unsafe { *input };
    let count = unsafe { *input.add(1) };
    if amount < -MAX_AMOUNT || amount > MAX_AMOUNT || count < 0 || count > MAX_DENOMINATIONS
        || length != (count + 2) as usize { return -1; }
    for index in 0..count as usize {
        let denomination = unsafe { *input.add(index + 2) };
        if denomination < 1 || denomination > MAX_AMOUNT { return -1; }
    }
    ways(amount, input, count)
}
