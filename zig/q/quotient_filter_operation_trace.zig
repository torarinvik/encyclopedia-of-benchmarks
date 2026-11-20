const SLOTS: usize = 8;
const MAX_OPS: usize = 32;
const MAX_ITEMS: usize = 6;

fn nextSlot(i: usize) usize { return (i + 1) % SLOTS; }
fn prevSlot(i: usize) usize { return (i + SLOTS - 1) % SLOTS; }

fn emptySlot(i: usize, rem: *const [SLOTS]u8, occ: *const [SLOTS]bool,
        cont: *const [SLOTS]bool, shifted: *const [SLOTS]bool) bool {
    return rem.*[i] == 0 and !occ.*[i] and !cont.*[i] and !shifted.*[i];
}

fn findRun(q: usize, occ: *const [SLOTS]bool, cont: *const [SLOTS]bool,
        shifted: *const [SLOTS]bool) i32 {
    if (!occ.*[q]) return -2;
    var bucket = q;
    var steps: usize = 0;
    while (shifted.*[bucket] and steps < SLOTS) : (steps += 1) bucket = prevSlot(bucket);
    if (steps >= SLOTS) return -1;
    var slot = bucket;
    while (bucket != q) {
        slot = nextSlot(slot);
        steps = 0;
        while (cont.*[slot] and steps < SLOTS) : (steps += 1) slot = nextSlot(slot);
        if (steps >= SLOTS) return -1;
        bucket = nextSlot(bucket);
        steps = 0;
        while (!occ.*[bucket] and steps < SLOTS) : (steps += 1) bucket = nextSlot(bucket);
        if (steps >= SLOTS) return -1;
    }
    return @intCast(slot);
}

fn findInsertPosition(q: usize, occ: *const [SLOTS]bool, cont: *const [SLOTS]bool,
        shifted: *const [SLOTS]bool) i32 {
    var bucket = q;
    var steps: usize = 0;
    while (shifted.*[bucket] and steps < SLOTS) : (steps += 1) bucket = prevSlot(bucket);
    if (steps >= SLOTS) return -1;
    var slot = bucket;
    while (bucket != q) {
        steps = 0;
        while (steps < SLOTS) {
            slot = nextSlot(slot);
            steps += 1;
            if (!cont.*[slot]) break;
        }
        if (steps >= SLOTS) return -1;
        bucket = nextSlot(bucket);
        steps = 0;
        while (bucket != q and !occ.*[bucket] and steps < SLOTS) : (steps += 1) bucket = nextSlot(bucket);
        if (steps >= SLOTS) return -1;
    }
    return @intCast(slot);
}

fn nextOccupied(q: usize, occ: *const [SLOTS]bool) i32 {
    var bucket = nextSlot(q);
    for (0..SLOTS) |_| {
        if (occ.*[bucket]) return @intCast(bucket);
        bucket = nextSlot(bucket);
    }
    return -1;
}

fn insertAt(position: usize, q: usize, r: u8, hasRun: bool, runStart: usize,
        rem: *[SLOTS]u8, occ: *[SLOTS]bool, cont: *[SLOTS]bool,
        shifted: *[SLOTS]bool) bool {
    const newCont = hasRun and position != runStart;
    if (hasRun and position == runStart) cont.*[position] = true;
    var empty = position;
    var foundEmpty = false;
    for (0..SLOTS) |_| {
        if (emptySlot(empty, rem, occ, cont, shifted)) { foundEmpty = true; break; }
        empty = nextSlot(empty);
    }
    if (!foundEmpty) return false;
    var slot = empty;
    while (slot != position) {
        const previous = prevSlot(slot);
        rem.*[slot] = rem.*[previous];
        cont.*[slot] = cont.*[previous];
        shifted.*[slot] = true;
        slot = previous;
    }
    rem.*[position] = r;
    cont.*[position] = newCont;
    shifted.*[position] = position != q;
    occ.*[q] = true;
    return true;
}

pub export fn quotient_filter_operation_trace(
    input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize,
) i64 {
    if (input == null or length < 1 or length > 66) return -1;
    const rawCount = input[0];
    if (rawCount < 0 or rawCount > @as(i64, MAX_OPS)) return -1;
    const count: usize = @intCast(rawCount);
    if (length != 1 + 2 * count) return -1;
    for (0..count) |op| {
        const opcode = input[1 + 2 * op];
        const fp = input[2 + 2 * op];
        if (opcode < 0 or opcode > 2 or fp < 0 or fp > 255) return -1;
    }
    if (output == null or capacity < count) return -2;

    var rem: [SLOTS]u8 = @splat(0);
    var occ: [SLOTS]bool = @splat(false);
    var cont: [SLOTS]bool = @splat(false);
    var shifted: [SLOTS]bool = @splat(false);
    var statuses: [MAX_OPS]u8 = @splat(0);
    var total: usize = 0;
    for (0..count) |op| {
        const opcode = input[1 + 2 * op];
        const fp: usize = @intCast(input[2 + 2 * op]);
        const q = fp >> 5;
        const r: u8 = @intCast(fp & 31);
        if (opcode == 0) {
            if (total == MAX_ITEMS) { statuses[op] = 2; continue; }
            var position_i = findRun(q, &occ, &cont, &shifted);
            if (position_i == -1) return -1;
            var position: usize = 0;
            const hasRun = position_i >= 0;
            var runStart: usize = 0;
            if (position_i >= 0) {
                position = @intCast(position_i);
                runStart = position;
                for (0..SLOTS) |_| {
                    if (rem[position] > r) break;
                    const next = nextSlot(position);
                    position = next;
                    if (!cont[next]) break;
                }
            } else if (!emptySlot(q, &rem, &occ, &cont, &shifted)) {
                position_i = findInsertPosition(q, &occ, &cont, &shifted);
                if (position_i < 0) return -1;
                position = @intCast(position_i);
            } else position = q;
            if (!hasRun) runStart = position;
            if (!insertAt(position, q, r, hasRun, runStart, &rem, &occ, &cont, &shifted)) return -1;
            total += 1;
            statuses[op] = 1;
        } else if (opcode == 1) {
            const start_i = findRun(q, &occ, &cont, &shifted);
            if (start_i == -1) return -1;
            var found = false;
            if (start_i >= 0) {
                var position: usize = @intCast(start_i);
                for (0..SLOTS) |_| {
                    if (rem[position] == r) { found = true; break; }
                    if (rem[position] > r) break;
                    const next = nextSlot(position);
                    if (!cont[next]) break;
                    position = next;
                }
            }
            statuses[op] = if (found) 1 else 0;
        } else {
            const start_i = findRun(q, &occ, &cont, &shifted);
            if (start_i == -1) return -1;
            var found_position: ?usize = null;
            if (start_i >= 0) {
                var position: usize = @intCast(start_i);
                for (0..SLOTS) |_| {
                    if (rem[position] == r) { found_position = position; break; }
                    if (rem[position] > r) break;
                    const next = nextSlot(position);
                    if (!cont[next]) break;
                    position = next;
                }
            }
            if (found_position == null) { statuses[op] = 0; continue; }
            const position = found_position.?;
            const wasRunStart = !cont[position];
            const following = nextSlot(position);
            const hasMoreSame = !emptySlot(following, &rem, &occ, &cont, &shifted) and cont[following];
            if (wasRunStart and !hasMoreSame) occ[q] = false;
            rem[position] = 0;
            cont[position] = false;
            shifted[position] = false;
            var hole = position;
            var currentQ = q;
            var firstShift = true;
            for (0..SLOTS - 1) |_| {
                const next = nextSlot(hole);
                if (emptySlot(next, &rem, &occ, &cont, &shifted) or !shifted[next]) break;
                const sourceCont = cont[next];
                const promote = firstShift and wasRunStart and hasMoreSame;
                if (!sourceCont and !promote) {
                    const next_q = nextOccupied(currentQ, &occ);
                    if (next_q < 0) return -1;
                    currentQ = @intCast(next_q);
                }
                rem[hole] = rem[next];
                cont[hole] = if (promote) false else sourceCont;
                shifted[hole] = cont[hole] or hole != currentQ;
                rem[next] = 0;
                cont[next] = false;
                shifted[next] = false;
                hole = next;
                firstShift = false;
            }
            rem[hole] = 0;
            cont[hole] = false;
            shifted[hole] = false;
            total -= 1;
            statuses[op] = 1;
        }
    }
    for (0..count) |i| output[i] = statuses[i];
    return @intCast(count);
}
