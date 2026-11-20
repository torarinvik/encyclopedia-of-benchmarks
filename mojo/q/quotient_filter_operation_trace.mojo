from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

comptime SLOTS = 8
comptime MAX_OPERATIONS = 32
comptime MAX_ITEMS = 6

fn qf_next(i: Int) -> Int:
    (i + 1) % SLOTS

fn qf_prev(i: Int) -> Int:
    (i + SLOTS - 1) % SLOTS

fn qf_empty(i: Int, rem: InlineArray[UInt8, SLOTS], occ: InlineArray[Bool, SLOTS],
        cont: InlineArray[Bool, SLOTS], shifted: InlineArray[Bool, SLOTS]) -> Bool:
    rem[i] == 0 and not occ[i] and not cont[i] and not shifted[i]

fn qf_find_run(q: Int, occ: InlineArray[Bool, SLOTS], cont: InlineArray[Bool, SLOTS],
        shifted: InlineArray[Bool, SLOTS]) -> Int:
    if not occ[q]: return -2
    var bucket = q
    var steps = 0
    while shifted[bucket] and steps < SLOTS:
        bucket = qf_prev(bucket)
        steps += 1
    if steps >= SLOTS: return -1
    var slot = bucket
    while bucket != q:
        slot = qf_next(slot)
        steps = 0
        while cont[slot] and steps < SLOTS:
            slot = qf_next(slot)
            steps += 1
        if steps >= SLOTS: return -1
        bucket = qf_next(bucket)
        steps = 0
        while not occ[bucket] and steps < SLOTS:
            bucket = qf_next(bucket)
            steps += 1
        if steps >= SLOTS: return -1
    slot

fn qf_find_insert_position(q: Int, occ: InlineArray[Bool, SLOTS],
        cont: InlineArray[Bool, SLOTS], shifted: InlineArray[Bool, SLOTS]) -> Int:
    var bucket = q
    var steps = 0
    while shifted[bucket] and steps < SLOTS:
        bucket = qf_prev(bucket)
        steps += 1
    if steps >= SLOTS: return -1
    var slot = bucket
    while bucket != q:
        steps = 0
        while steps < SLOTS:
            slot = qf_next(slot)
            steps += 1
            if not cont[slot]: break
        if steps >= SLOTS: return -1
        bucket = qf_next(bucket)
        steps = 0
        while bucket != q and not occ[bucket] and steps < SLOTS:
            bucket = qf_next(bucket)
            steps += 1
        if steps >= SLOTS: return -1
    slot

fn qf_next_occupied(q: Int, occ: InlineArray[Bool, SLOTS]) -> Int:
    var bucket = qf_next(q)
    for _ in range(SLOTS):
        if occ[bucket]: return bucket
        bucket = qf_next(bucket)
    -1

fn qf_insert_at(position: Int, q: Int, r: UInt8, has_run: Bool, run_start: Int,
        mut rem: InlineArray[UInt8, SLOTS], mut occ: InlineArray[Bool, SLOTS],
        mut cont: InlineArray[Bool, SLOTS], mut shifted: InlineArray[Bool, SLOTS]) -> Bool:
    let new_cont = has_run and position != run_start
    if has_run and position == run_start: cont[position] = True
    var empty = position
    var found_empty = False
    for _ in range(SLOTS):
        if qf_empty(empty, rem, occ, cont, shifted):
            found_empty = True
            break
        empty = qf_next(empty)
    if not found_empty: return False
    var slot = empty
    while slot != position:
        let previous = qf_prev(slot)
        rem[slot] = rem[previous]
        cont[slot] = cont[previous]
        shifted[slot] = True
        slot = previous
    rem[position] = r
    cont[position] = new_cont
    shifted[position] = position != q
    occ[q] = True
    True

@export("quotient_filter_operation_trace")
fn quotient_filter_operation_trace(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin],
        capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 66: return -1
    let raw_count = input[0]
    if raw_count < 0 or raw_count > MAX_OPERATIONS: return -1
    let count = Int(raw_count)
    if length != c_size_t(1 + 2 * count): return -1
    for op in range(count):
        let opcode = input[1 + 2 * op]
        let fp = input[2 + 2 * op]
        if opcode < 0 or opcode > 2 or fp < 0 or fp > 255: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(count): return -2

    var rem = InlineArray[UInt8, SLOTS](fill=0)
    var occ = InlineArray[Bool, SLOTS](fill=False)
    var cont = InlineArray[Bool, SLOTS](fill=False)
    var shifted = InlineArray[Bool, SLOTS](fill=False)
    var statuses = InlineArray[UInt8, MAX_OPERATIONS](fill=0)
    var total = 0
    for op in range(count):
        let opcode = input[1 + 2 * op]
        let fp = Int(input[2 + 2 * op])
        let q = fp >> 5
        let r = UInt8(fp & 31)
        if opcode == 0:
            if total == MAX_ITEMS:
                statuses[op] = 2
                continue
            var position = qf_find_run(q, occ, cont, shifted)
            if position == -1: return -1
            var run_start = position
            var has_run = position >= 0
            if position >= 0:
                for _ in range(SLOTS):
                    if rem[position] > r: break
                    let next = qf_next(position)
                    position = next
                    if not cont[next]: break
            elif not qf_empty(q, rem, occ, cont, shifted):
                position = qf_find_insert_position(q, occ, cont, shifted)
                if position < 0: return -1
            if position == -2: position = q
            if not has_run: run_start = position
            if not qf_insert_at(position, q, r, has_run, run_start,
                    mut rem, mut occ, mut cont, mut shifted): return -1
            total += 1
            statuses[op] = 1
        elif opcode == 1:
            var position = qf_find_run(q, occ, cont, shifted)
            if position == -1: return -1
            var found = False
            if position >= 0:
                for _ in range(SLOTS):
                    if rem[position] == r:
                        found = True
                        break
                    if rem[position] > r: break
                    let next = qf_next(position)
                    if not cont[next]: break
                    position = next
            statuses[op] = 1 if found else 0
        else:
            var position = qf_find_run(q, occ, cont, shifted)
            if position == -1: return -1
            var removed = False
            if position >= 0:
                for _ in range(SLOTS):
                    if rem[position] == r:
                        removed = True
                        break
                    if rem[position] > r: break
                    let next = qf_next(position)
                    if not cont[next]: break
                    position = next
            if not removed:
                statuses[op] = 0
                continue
            let was_run_start = not cont[position]
            let following = qf_next(position)
            let has_more_same = not qf_empty(following, rem, occ, cont, shifted) and cont[following]
            if was_run_start and not has_more_same: occ[q] = False
            rem[position] = 0
            cont[position] = False
            shifted[position] = False
            var hole = position
            var current_q = q
            var first_shift = True
            for _ in range(SLOTS - 1):
                let next = qf_next(hole)
                if qf_empty(next, rem, occ, cont, shifted) or not shifted[next]: break
                let source_cont = cont[next]
                let promote = first_shift and was_run_start and has_more_same
                if not source_cont and not promote:
                    current_q = qf_next_occupied(current_q, occ)
                    if current_q < 0: return -1
                rem[hole] = rem[next]
                cont[hole] = False if promote else source_cont
                shifted[hole] = cont[hole] or hole != current_q
                rem[next] = 0
                cont[next] = False
                shifted[next] = False
                hole = next
                first_shift = False
            rem[hole] = 0
            cont[hole] = False
            shifted[hole] = False
            total -= 1
            statuses[op] = 1
    for op in range(count): output.add(op).write(statuses[op])
    Int64(count)
