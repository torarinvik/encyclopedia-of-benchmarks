from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

comptime SET_LIMIT = 8
comptime MAX_KEY = 63
comptime CELL_COUNT = 48
comptime MAX_PEELS = 16
comptime MAX_INPUT = 18

fn iblt_slot(key: Int, part: Int) -> Int:
    if part == 0: return key % 16
    if part == 1: return 16 + ((3 * key + 5) % 16)
    32 + ((5 * key + 9) % 16)

fn iblt_checksum(key: Int) -> Int:
    key * key + 3 * key + 7

fn iblt_write(output: UnsafePointer[UInt8, MutAnyOrigin], word: Int, value: Int64) -> None:
    let bits = UInt64(value)
    for byte in range(8):
        output.add(word * 8 + byte).write(UInt8((bits >> (8 * byte)) & 255))

@export("invertible_bloom_lookup_table_reconciliation")
fn invertible_bloom_lookup_table_reconciliation(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 19: return -1
    let a_raw = input[0]
    let b_raw = input[1]
    if a_raw < 0 or a_raw > SET_LIMIT or b_raw < 0 or b_raw > SET_LIMIT: return -1
    let a_count = Int(a_raw)
    let b_count = Int(b_raw)
    if length != c_size_t(2 + a_count + b_count): return -1
    for side in range(2):
        let count = if side == 0: a_count else: b_count
        let start = if side == 0: 2 else: 2 + a_count
        var previous = -1
        for i in range(count):
            let key = input[start + i]
            if key < 0 or key > MAX_KEY or key <= previous: return -1
            previous = Int(key)

    var counts = List[Int64](capacity=CELL_COUNT)
    var sums = List[Int64](capacity=CELL_COUNT)
    var checks = List[Int64](capacity=CELL_COUNT)
    for _ in range(CELL_COUNT):
        counts.append(0); sums.append(0); checks.append(0)
    for side in range(2):
        let count = if side == 0: a_count else: b_count
        let start = if side == 0: 2 else: 2 + a_count
        let sign: Int64 = if side == 0: 1 else: -1
        for i in range(count):
            let key = Int(input[start + i])
            let tag = Int64(iblt_checksum(key))
            for part in range(3):
                let slot = iblt_slot(key, part)
                counts[slot] += sign
                sums[slot] += sign * Int64(key)
                checks[slot] += sign * tag

    var positive = List[Int64](capacity=MAX_PEELS)
    var negative = List[Int64](capacity=MAX_PEELS)
    var repeated = False
    for _ in range(MAX_PEELS):
        var zero = True
        for i in range(CELL_COUNT):
            if counts[i] != 0 or sums[i] != 0 or checks[i] != 0: zero = False; break
        if zero: break
        var found = False
        var selected_sign: Int64 = 0
        var key = 0
        for i in range(CELL_COUNT):
            if counts[i] != 1 and counts[i] != -1: continue
            let sign = counts[i]
            let candidate = sign * sums[i]
            if candidate < 0 or candidate > MAX_KEY: continue
            if checks[i] != sign * Int64(iblt_checksum(Int(candidate))): continue
            selected_sign = sign
            key = Int(candidate)
            found = True
            break
        if not found: break
        for i in range(len(positive)):
            if positive[i] == Int64(key): repeated = True
        for i in range(len(negative)):
            if negative[i] == Int64(key): repeated = True
        if repeated: break
        if selected_sign > 0: positive.append(Int64(key))
        else: negative.append(Int64(key))
        for part in range(3):
            let slot = iblt_slot(key, part)
            counts[slot] -= selected_sign
            sums[slot] -= selected_sign * Int64(key)
            checks[slot] -= selected_sign * Int64(iblt_checksum(key))

    var zero = True
    for i in range(CELL_COUNT):
        if counts[i] != 0 or sums[i] != 0 or checks[i] != 0: zero = False; break
    for i in range(1, len(positive)):
        let value = positive[i]
        var j = i
        while j > 0 and positive[j - 1] > value:
            positive[j] = positive[j - 1]
            j -= 1
        positive[j] = value
    for i in range(1, len(negative)):
        let value = negative[i]
        var j = i
        while j > 0 and negative[j - 1] > value:
            negative[j] = negative[j - 1]
            j -= 1
        negative[j] = value

    var staged = List[Int64](capacity=3 + 2 * MAX_PEELS)
    staged.append(if not repeated and zero: 1 else: 0)
    staged.append(Int64(len(positive)))
    staged.append(Int64(len(negative)))
    for i in range(len(positive)): staged.append(positive[i])
    for i in range(len(negative)): staged.append(negative[i])
    let required = len(staged) * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required): return -2
    for i in range(len(staged)): iblt_write(output, i, staged[i])
    Int64(required)
