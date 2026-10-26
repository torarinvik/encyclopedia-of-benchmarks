const MAX_PACKETS: usize = 16;
const MAX_SLOTS: usize = 8;
const MAX_INPUT: usize = 38;
const MAX_OUTPUT_BYTES: usize = 64;
const BETA: i64 = 15;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

fn erase_at(residents: &mut [(i64, i64); MAX_PACKETS], count: &mut usize, index: usize) {
    for position in index..(*count - 1) { residents[position] = residents[position + 1]; }
    *count -= 1;
}

#[no_mangle]
pub unsafe extern "C" fn packet_switching_single_buffer(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 5 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (mode, buffer_value, beta, slots_value, count_value) =
        (values[0], values[1], values[2], values[3], values[4]);
    if !(0..=2).contains(&mode) || !(1..=4).contains(&buffer_value) ||
        !(1..=MAX_SLOTS as i64).contains(&slots_value) || !(0..=MAX_PACKETS as i64).contains(&count_value) ||
        length != 5 + 2 * count_value as usize || (mode == 0 && beta != 0) || (mode != 0 && beta != BETA) { return -1; }
    let slots = slots_value as usize;
    let packet_count = count_value as usize;
    let mut arrival = [0i64; MAX_PACKETS];
    let mut packet_values = [0i64; MAX_PACKETS];
    let mut previous_slot = -1i64;
    for packet in 0..packet_count {
        arrival[packet] = values[5 + 2 * packet];
        packet_values[packet] = values[6 + 2 * packet];
        if arrival[packet] < 0 || arrival[packet] >= slots_value || arrival[packet] < previous_slot ||
            !(1..=100).contains(&packet_values[packet]) { return -1; }
        previous_slot = arrival[packet];
    }
    let mut residents = [(0i64, 0i64); MAX_PACKETS];
    let mut resident_count = 0usize;
    let mut schedule = [-1i64; MAX_SLOTS];
    let mut next_packet = 0usize;
    for slot in 0..slots {
        while next_packet < packet_count && arrival[next_packet] == slot as i64 {
            let value = packet_values[next_packet];
            let mut preempt = resident_count;
            if mode == 1 {
                for index in 0..resident_count {
                    if residents[index].1 * BETA <= value { preempt = index; break; }
                }
            } else if mode == 2 {
                for index in 0..resident_count {
                    let following_ok = index + 1 == resident_count || residents[index].1 <= residents[index + 1].1;
                    if residents[index].1 * BETA < value && following_ok { preempt = index; break; }
                }
            }
            let new_packet = (next_packet as i64, value);
            if preempt < resident_count {
                erase_at(&mut residents, &mut resident_count, preempt);
                residents[resident_count] = new_packet; resident_count += 1;
            } else if resident_count < buffer_value as usize {
                residents[resident_count] = new_packet; resident_count += 1;
            } else {
                let smallest = residents[..resident_count].iter().map(|packet| packet.1).min().unwrap();
                if value > smallest {
                    let evict = residents[..resident_count].iter().position(|packet| packet.1 == smallest).unwrap();
                    erase_at(&mut residents, &mut resident_count, evict);
                    residents[resident_count] = new_packet; resident_count += 1;
                }
            }
            next_packet += 1;
        }
        if resident_count > 0 {
            schedule[slot] = residents[0].0;
            erase_at(&mut residents, &mut resident_count, 0);
        }
    }
    let output_bytes = 8 * slots;
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut staged = [0u8; MAX_OUTPUT_BYTES];
    for slot in 0..slots { store_i64_le(staged.as_mut_ptr(), 8 * slot, schedule[slot]); }
    for byte in 0..output_bytes { *output.add(byte) = staged[byte]; }
    output_bytes as i64
}
