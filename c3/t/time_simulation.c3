module time_simulation;

const usz MAX_EVENTS = 1024;
const usz MAX_ACTIONS = 4096;
const ulong MAX_EVENT_ID = 4294967295u64;
fn ulong hash_word(ulong hash, ulong word) {
    for (uint shift = 0; shift < 64; shift += 8) { hash ^= (word >> shift) & 255; hash *= 1099511628211u64; }
    return hash;
}
long time_simulation(long* values, usz length) @export("time_simulation") {
    if (values == null || length < 1 || length > 8194) return -1;
    long count = values[0];
    if (count < 0 || count > 4096 || length != (usz)(1 + 2 * count)) return -1;
    ulong hash = hash_word(14695981039346656037u64, (ulong)count);
    long now = 0; ulong next_id = 1;
    usz active_count = 0, total_processed = 0, fired_count = 0;
    bool[MAX_EVENTS] active; long[MAX_EVENTS] timestamps; ulong[MAX_EVENTS] event_ids;
    // Reused queue slots can fire repeatedly, so trace storage spans all actions.
    ulong[MAX_ACTIONS] fired_ids; long[MAX_ACTIONS] fired_times;
    for (usz action = 0; action < (usz)count; action++) {
        long opcode = values[1+2*action], operand = values[2+2*action]; ulong result = 0;
        if (opcode == 0) {
            if (operand < 0 || operand < now) return -1;
            if (active_count < MAX_EVENTS) {
                usz slot = 0; while (active[slot]) slot++;
                event_ids[slot] = next_id; timestamps[slot] = operand; active[slot] = true; active_count++;
                result = next_id++; if (next_id > MAX_EVENT_ID) next_id = 1;
            }
        } else if (opcode == 1) {
            if (operand < 1 || (ulong)operand > MAX_EVENT_ID) return -1;
            for (usz slot = 0; slot < MAX_EVENTS; slot++) if (active[slot] && event_ids[slot] == (ulong)operand) { active[slot] = false; active_count--; result = 1; break; }
        } else if (opcode == 2) {
            if (operand < 0 || operand < now) return -1;
            usz processed = 0;
            while (true) {
                usz chosen = MAX_EVENTS; long earliest = 0;
                for (usz slot = 0; slot < MAX_EVENTS; slot++) if (active[slot] && timestamps[slot] <= operand && (chosen == MAX_EVENTS || timestamps[slot] < earliest)) { chosen = slot; earliest = timestamps[slot]; }
                if (chosen == MAX_EVENTS) break;
                now = timestamps[chosen]; active[chosen] = false; active_count--;
                fired_ids[fired_count] = event_ids[chosen]; fired_times[fired_count] = timestamps[chosen]; fired_count++;
                processed++; total_processed++;
            }
            now = operand; result = processed;
        } else if (opcode == 3) { if (operand != 0) return -1; result = (ulong)now; }
        else if (opcode == 4) { if (operand != 0) return -1; result = active_count == 0 ? 1 : 0; }
        else return -1;
        hash = hash_word(hash, result);
    }
    hash = hash_word(hash, (ulong)fired_count);
    for (usz i = 0; i < fired_count; i++) { hash = hash_word(hash, fired_ids[i]); hash = hash_word(hash, (ulong)fired_times[i]); }
    hash = hash_word(hash, (ulong)now); hash = hash_word(hash, (ulong)active_count); hash = hash_word(hash, (ulong)total_processed);
    return (long)(hash & 0x7FFFFFFFFFFFFFFFu64);
}
