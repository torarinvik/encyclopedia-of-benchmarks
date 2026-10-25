module main

const max_events = 64
const max_epoch = i64(15)
const max_address = i64(255)

@[export: 'analyzer']
pub fn analyzer(input &i64, length usize) i64 {
    if unsafe { input == nil } || length < 1 || length > 194 { return -1 }
    count_value := unsafe { input[0] }
    if count_value < 0 || count_value > max_events { return -1 }
    count := int(count_value)
    if length != usize(1 + 3 * count) { return -1 }
    mut latest_writer := [256]i64{}
    for address in 0 .. 256 { latest_writer[address] = -1 }
    mut conflicts := i64(0)
    mut previous_epoch := i64(0)
    for event in 0 .. count {
        base := 1 + 3 * event
        epoch := unsafe { input[base] }
        opcode := unsafe { input[base + 1] }
        address_value := unsafe { input[base + 2] }
        if epoch < previous_epoch || epoch < 0 || epoch > max_epoch
            || (opcode != 0 && opcode != 1) || address_value < 0 || address_value > max_address { return -1 }
        previous_epoch = epoch
        address := int(address_value)
        if opcode == 0 {
            latest_writer[address] = i64(event)
        } else {
            for prior in 0 .. event {
                prior_base := 1 + 3 * prior
                if unsafe { input[prior_base] } < epoch && unsafe { input[prior_base + 1] } == 0
                    && unsafe { input[prior_base + 2] } == address_value
                    && latest_writer[address] == i64(prior) { conflicts++ }
            }
        }
    }
    return conflicts
}
