const MAX_EVENTS: usize = 64;
const MAX_EPOCH: i64 = 15;
const MAX_ADDRESS: i64 = 255;

#[no_mangle]
pub unsafe extern "C" fn analyzer(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > 194 { return -1; }
    let count_value = *input;
    if !(0..=MAX_EVENTS as i64).contains(&count_value) { return -1; }
    let count = count_value as usize;
    if length != 1 + 3 * count { return -1; }
    let mut latest_writer = [-1i64; 256];
    let mut conflicts = 0i64;
    let mut previous_epoch = 0i64;
    for event in 0..count {
        let base = 1 + 3 * event;
        let epoch = *input.add(base);
        let opcode = *input.add(base + 1);
        let address_value = *input.add(base + 2);
        if epoch < previous_epoch || !(0..=MAX_EPOCH).contains(&epoch)
            || (opcode != 0 && opcode != 1) || !(0..=MAX_ADDRESS).contains(&address_value) { return -1; }
        previous_epoch = epoch;
        let address = address_value as usize;
        if opcode == 0 {
            latest_writer[address] = event as i64;
        } else {
            for prior in 0..event {
                let prior_base = 1 + 3 * prior;
                if *input.add(prior_base) < epoch && *input.add(prior_base + 1) == 0
                    && *input.add(prior_base + 2) == address_value
                    && latest_writer[address] == prior as i64 { conflicts += 1; }
            }
        }
    }
    conflicts
}
