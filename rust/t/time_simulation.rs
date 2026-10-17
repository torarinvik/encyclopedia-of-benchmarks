const MAX_ACTIONS: usize = 4096;
const MAX_EVENTS: usize = 1024;
const MAX_EVENT_ID: u64 = u32::MAX as u64;
fn hash_word(mut hash: u64, word: u64) -> u64 {
    for shift in (0..64).step_by(8) { hash ^= (word >> shift) & 255; hash = hash.wrapping_mul(1_099_511_628_211); }
    hash
}
#[no_mangle]
pub unsafe extern "C" fn time_simulation(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 1 || length > 8194 { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let count = input[0];
    if !(0..=MAX_ACTIONS as i64).contains(&count) || length != 1 + 2 * count as usize { return -1; }
    let mut hash = hash_word(14_695_981_039_346_656_037, count as u64);
    let mut now = 0i64; let mut next_id = 1u64; let mut active_count = 0usize; let mut total_processed = 0usize; let mut fired_count = 0usize;
    let mut active = [false; MAX_EVENTS]; let mut timestamps = [0i64; MAX_EVENTS]; let mut event_ids = [0u64; MAX_EVENTS];
    // Reused queue slots can fire repeatedly, so trace storage spans all actions.
    let mut fired_ids = [0u64; MAX_ACTIONS]; let mut fired_times = [0i64; MAX_ACTIONS];
    for action in 0..count as usize {
        let opcode = input[1 + 2 * action]; let operand = input[2 + 2 * action]; let mut result = 0u64;
        if opcode == 0 {
            if operand < 0 || operand < now { return -1; }
            if active_count < MAX_EVENTS {
                let slot = active.iter().position(|&is_active| !is_active).unwrap();
                event_ids[slot] = next_id; timestamps[slot] = operand; active[slot] = true; active_count += 1;
                result = next_id; next_id += 1; if next_id > MAX_EVENT_ID { next_id = 1; }
            }
        } else if opcode == 1 {
            if operand < 1 || operand as u64 > MAX_EVENT_ID { return -1; }
            if let Some(slot) = (0..MAX_EVENTS).find(|&slot| active[slot] && event_ids[slot] == operand as u64) { active[slot] = false; active_count -= 1; result = 1; }
        } else if opcode == 2 {
            if operand < 0 || operand < now { return -1; }
            let mut processed = 0u64;
            loop {
                let mut chosen = None; let mut earliest = 0i64;
                for slot in 0..MAX_EVENTS { if active[slot] && timestamps[slot] <= operand && (chosen.is_none() || timestamps[slot] < earliest) { chosen = Some(slot); earliest = timestamps[slot]; } }
                let Some(slot) = chosen else { break; };
                now = timestamps[slot]; active[slot] = false; active_count -= 1;
                fired_ids[fired_count] = event_ids[slot]; fired_times[fired_count] = timestamps[slot]; fired_count += 1;
                processed += 1; total_processed += 1;
            }
            now = operand; result = processed;
        } else if opcode == 3 { if operand != 0 { return -1; } result = now as u64; }
        else if opcode == 4 { if operand != 0 { return -1; } result = if active_count == 0 { 1 } else { 0 }; }
        else { return -1; }
        hash = hash_word(hash, result);
    }
    hash = hash_word(hash, fired_count as u64);
    for i in 0..fired_count { hash = hash_word(hash, fired_ids[i]); hash = hash_word(hash, fired_times[i] as u64); }
    hash = hash_word(hash, now as u64); hash = hash_word(hash, active_count as u64); hash = hash_word(hash, total_processed as u64);
    (hash & 0x7FFF_FFFF_FFFF_FFFF) as i64
}
