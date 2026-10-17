package time_simulation

import "core:c"

MAX_EVENTS :: 1024
MAX_ACTIONS :: 4096
MAX_EVENT_ID :: u64(4_294_967_295)

hash_word :: proc(hash_input, word: u64) -> u64 {
    hash := hash_input
    for shift := 0; shift < 64; shift += 8 { hash = (hash ^ ((word >> u64(shift)) & 255)) * 1_099_511_628_211 }
    return hash
}

@(export)
time_simulation :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 1 || length > 8194 do return -1
    count := values[0]
    if count < 0 || count > 4096 || length != 1 + 2 * c.size_t(count) do return -1
    hash := hash_word(14_695_981_039_346_656_037, u64(count))
    now := i64(0); next_id := u64(1); active_count, total_processed, fired_count := 0, 0, 0
    active: [MAX_EVENTS]bool; timestamps: [MAX_EVENTS]i64; event_ids: [MAX_EVENTS]u64
    // Reused queue slots can fire repeatedly, so trace storage spans all actions.
    fired_ids: [MAX_ACTIONS]u64; fired_times: [MAX_ACTIONS]i64
    for action: c.size_t = 0; action < c.size_t(count); action += 1 {
        opcode, operand := values[1 + 2*action], values[2 + 2*action]
        result := u64(0)
        if opcode == 0 {
            if operand < 0 || operand < now do return -1
            if active_count < MAX_EVENTS {
                slot := 0; for active[slot] { slot += 1 }
                event_ids[slot] = next_id; timestamps[slot] = operand; active[slot] = true; active_count += 1
                result = next_id; next_id += 1; if next_id > MAX_EVENT_ID do next_id = 1
            }
        } else if opcode == 1 {
            if operand < 1 || u64(operand) > MAX_EVENT_ID do return -1
            for slot := 0; slot < MAX_EVENTS; slot += 1 {
                if active[slot] && event_ids[slot] == u64(operand) { active[slot] = false; active_count -= 1; result = 1; break }
            }
        } else if opcode == 2 {
            if operand < 0 || operand < now do return -1
            processed := 0
            for {
                chosen := -1; earliest := i64(0)
                for slot := 0; slot < MAX_EVENTS; slot += 1 {
                    if active[slot] && timestamps[slot] <= operand && (chosen < 0 || timestamps[slot] < earliest) { chosen = slot; earliest = timestamps[slot] }
                }
                if chosen < 0 { break }
                now = timestamps[chosen]; active[chosen] = false; active_count -= 1
                fired_ids[fired_count] = event_ids[chosen]; fired_times[fired_count] = timestamps[chosen]; fired_count += 1
                processed += 1; total_processed += 1
            }
            now = operand; result = u64(processed)
        } else if opcode == 3 { if operand != 0 do return -1; result = u64(now) }
        else if opcode == 4 { if operand != 0 do return -1; result = u64(active_count == 0) }
        else do return -1
        hash = hash_word(hash, result)
    }
    hash = hash_word(hash, u64(fired_count))
    for i := 0; i < fired_count; i += 1 { hash = hash_word(hash, fired_ids[i]); hash = hash_word(hash, u64(fired_times[i])) }
    hash = hash_word(hash, u64(now)); hash = hash_word(hash, u64(active_count)); hash = hash_word(hash, u64(total_processed))
    return i64(hash & 0x7FFFFFFFFFFFFFFF)
}
