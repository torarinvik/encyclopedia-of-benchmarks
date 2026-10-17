module time_simulation

const max_events = 1024
const max_actions = 4096
const max_event_id = u64(4294967295)

fn hash_word(hash_input u64, word u64) u64 {
    mut hash := hash_input
    for shift := 0; shift < 64; shift += 8 { hash = (hash ^ ((word >> shift) & 255)) * u64(1099511628211) }
    return hash
}

@[export: 'time_simulation']
pub fn time_simulation(values &i64, length usize) i64 {
    if unsafe { values == nil } || length < 1 || length > 8194 { return -1 }
    count := unsafe { values[0] }
    if count < 0 || count > 4096 || length != 1 + 2 * usize(count) { return -1 }
    mut hash := hash_word(u64(14695981039346656037), u64(count))
    mut now := i64(0); mut next_id := u64(1); mut active_count := 0; mut total_processed := 0; mut fired_count := 0
    mut active := [max_events]bool{}; mut timestamps := [max_events]i64{}; mut event_ids := [max_events]u64{}
    // Reused queue slots can fire repeatedly, so trace storage spans all actions.
    mut fired_ids := [max_actions]u64{}; mut fired_times := [max_actions]i64{}
    for action in 0 .. int(count) {
        opcode := unsafe { values[1 + 2 * action] }; operand := unsafe { values[2 + 2 * action] }; mut result := u64(0)
        if opcode == 0 {
            if operand < 0 || operand < now { return -1 }
            if active_count < max_events {
                mut slot := 0; for active[slot] { slot++ }
                event_ids[slot] = next_id; timestamps[slot] = operand; active[slot] = true; active_count++
                result = next_id; next_id++; if next_id > max_event_id { next_id = 1 }
            }
        } else if opcode == 1 {
            if operand < 1 || u64(operand) > max_event_id { return -1 }
            for slot in 0 .. max_events { if active[slot] && event_ids[slot] == u64(operand) { active[slot] = false; active_count--; result = 1; break } }
        } else if opcode == 2 {
            if operand < 0 || operand < now { return -1 }
            mut processed := 0
            for {
                mut chosen := -1; mut earliest := i64(0)
                for slot in 0 .. max_events { if active[slot] && timestamps[slot] <= operand && (chosen < 0 || timestamps[slot] < earliest) { chosen = slot; earliest = timestamps[slot] } }
                if chosen < 0 { break }
                now = timestamps[chosen]; active[chosen] = false; active_count--
                fired_ids[fired_count] = event_ids[chosen]; fired_times[fired_count] = timestamps[chosen]; fired_count++
                processed++; total_processed++
            }
            now = operand; result = u64(processed)
        } else if opcode == 3 { if operand != 0 { return -1 }; result = u64(now) }
        else if opcode == 4 { if operand != 0 { return -1 }; result = if active_count == 0 { u64(1) } else { u64(0) } }
        else { return -1 }
        hash = hash_word(hash, result)
    }
    hash = hash_word(hash, u64(fired_count))
    for i in 0 .. fired_count { hash = hash_word(hash, fired_ids[i]); hash = hash_word(hash, u64(fired_times[i])) }
    hash = hash_word(hash, u64(now)); hash = hash_word(hash, u64(active_count)); hash = hash_word(hash, u64(total_processed))
    return i64(hash & u64(0x7FFFFFFFFFFFFFFF))
}
