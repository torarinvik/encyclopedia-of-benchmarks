const MAX_QUEUES: usize = 4;
const MAX_SLOTS: usize = 8;
const MAX_INPUT: usize = 36;
const MAX_OUTPUT_BYTES: usize = 64;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn packet_switching_sgr_multi_queue(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (queue_value, buffer_value, slot_value) = (values[0], values[1], values[2]);
    if !(2..=MAX_QUEUES as i64).contains(&queue_value) || !(1..=4).contains(&buffer_value) ||
        !(1..=MAX_SLOTS as i64).contains(&slot_value) { return -1; }
    let (queues, buffer, slots) = (queue_value as usize, buffer_value, slot_value as usize);
    if length != 3 + queues * slots { return -1; }
    let mut load = [0i64; MAX_QUEUES];
    let mut peak = [0i64; MAX_QUEUES];
    let mut schedule = [-1i64; MAX_SLOTS];
    for slot in 0..slots {
        for queue in 0..queues {
            let arrivals = values[3 + slot * queues + queue];
            if arrivals < 0 || arrivals > buffer { return -1; }
            load[queue] = (load[queue] + arrivals).min(buffer);
            peak[queue] = peak[queue].max(load[queue]);
        }
        let mut has_large = false;
        let mut has_nonempty = false;
        let mut has_underfull_peak = false;
        for queue in 0..queues {
            if load[queue] > 0 {
                has_nonempty = true;
                has_large |= load[queue] > buffer / 2;
                has_underfull_peak |= peak[queue] < buffer;
            }
        }
        if !has_nonempty { peak = [0; MAX_QUEUES]; continue; }
        let use_history = !has_large && has_underfull_peak;
        let mut selected = queues;
        for queue in 0..queues {
            if load[queue] == 0 || use_history && peak[queue] >= buffer { continue; }
            if selected == queues || load[queue] > load[selected] { selected = queue; }
        }
        schedule[slot] = selected as i64;
        load[selected] -= 1;
        if load[..queues].iter().all(|&amount| amount == 0) { peak = [0; MAX_QUEUES]; }
    }
    let output_bytes = 8 * slots;
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut staged = [0u8; MAX_OUTPUT_BYTES];
    for slot in 0..slots { store_i64_le(staged.as_mut_ptr(), 8 * slot, schedule[slot]); }
    for byte in 0..output_bytes { *output.add(byte) = staged[byte]; }
    output_bytes as i64
}
