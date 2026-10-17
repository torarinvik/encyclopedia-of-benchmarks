const MAX_ACTIONS: usize = 4096;
const MAX_EVENTS: usize = 1024;
const MAX_EVENT_ID: u64 = 4294967295;
fn hashWord(initial: u64, word: u64) u64 {
    var hash = initial;
    for (0..8) |byte| { hash ^= (word >> @intCast(byte * 8)) & 255; hash *%= 1099511628211; }
    return hash;
}
export fn time_simulation(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 1 or length > 8194) return -1;
    const count = values[0];
    if (count < 0 or count > 4096 or length != 1 + 2 * @as(usize, @intCast(count))) return -1;
    var hash = hashWord(14695981039346656037, @intCast(count));
    var now: i64 = 0; var next_id: u64 = 1; var active_count: usize = 0; var total_processed: usize = 0; var fired_count: usize = 0;
    var active = [_]bool{false} ** MAX_EVENTS; var timestamps = [_]i64{0} ** MAX_EVENTS; var event_ids = [_]u64{0} ** MAX_EVENTS;
    // Reused queue slots can fire repeatedly, so trace storage spans all actions.
    var fired_ids = [_]u64{0} ** MAX_ACTIONS; var fired_times = [_]i64{0} ** MAX_ACTIONS;
    for (0..@as(usize, @intCast(count))) |action| {
        const opcode = values[1 + 2 * action]; const operand = values[2 + 2 * action]; var result: u64 = 0;
        if (opcode == 0) {
            if (operand < 0 or operand < now) return -1;
            if (active_count < MAX_EVENTS) {
                var slot: usize = 0; while (active[slot]) : (slot += 1) {}
                event_ids[slot] = next_id; timestamps[slot] = operand; active[slot] = true; active_count += 1;
                result = next_id; next_id += 1; if (next_id > MAX_EVENT_ID) next_id = 1;
            }
        } else if (opcode == 1) {
            if (operand < 1 or @as(u64, @intCast(operand)) > MAX_EVENT_ID) return -1;
            for (0..MAX_EVENTS) |slot| if (active[slot] and event_ids[slot] == @as(u64, @intCast(operand))) { active[slot] = false; active_count -= 1; result = 1; break; };
        } else if (opcode == 2) {
            if (operand < 0 or operand < now) return -1;
            var processed: u64 = 0;
            while (true) {
                var chosen: ?usize = null; var earliest: i64 = 0;
                for (0..MAX_EVENTS) |slot| if (active[slot] and timestamps[slot] <= operand and (chosen == null or timestamps[slot] < earliest)) { chosen = slot; earliest = timestamps[slot]; };
                if (chosen) |slot| {
                    now = timestamps[slot]; active[slot] = false; active_count -= 1;
                    fired_ids[fired_count] = event_ids[slot]; fired_times[fired_count] = timestamps[slot]; fired_count += 1;
                    processed += 1; total_processed += 1;
                } else break;
            }
            now = operand; result = processed;
        } else if (opcode == 3) { if (operand != 0) return -1; result = @intCast(now); }
        else if (opcode == 4) { if (operand != 0) return -1; result = if (active_count == 0) 1 else 0; }
        else return -1;
        hash = hashWord(hash, result);
    }
    hash = hashWord(hash, fired_count);
    for (0..fired_count) |i| { hash = hashWord(hash, fired_ids[i]); hash = hashWord(hash, @intCast(fired_times[i])); }
    hash = hashWord(hash, @intCast(now)); hash = hashWord(hash, active_count); hash = hashWord(hash, total_processed);
    return @intCast(hash & 0x7FFFFFFFFFFFFFFF);
}
