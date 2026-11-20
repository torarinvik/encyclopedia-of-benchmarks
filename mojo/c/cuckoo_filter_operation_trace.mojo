from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

comptime BUCKETS = 8
comptime WIDTH = 4
comptime MAX_OPERATIONS = 32
comptime MAX_KICKS = 8

fn cf_delta(fingerprint: Int64) -> Int:
    1 + ((5 * Int(fingerprint) + 3) % 7)

fn cf_write(output: UnsafePointer[UInt8, MutAnyOrigin], index: Int, value: Int64) -> None:
    let bits = UInt64(value)
    for byte in range(8):
        output.add(index * 8 + byte).write(UInt8((bits >> (8 * byte)) & 255))

@export("cuckoo_filter_operation_trace")
fn cuckoo_filter_operation_trace(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin],
        capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 98: return -1
    let raw_count = input[0]
    if raw_count < 1 or raw_count > MAX_OPERATIONS: return -1
    let count = Int(raw_count)
    if length != c_size_t(1 + 3 * count): return -1
    for operation in range(count):
        let opcode = input[1 + 3 * operation]
        let primary = input[2 + 3 * operation]
        let fingerprint = input[3 + 3 * operation]
        if opcode < 0 or opcode > 2 or primary < 0 or primary >= BUCKETS or
                fingerprint < 1 or fingerprint > 15: return -1
    let required = count * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required): return -2

    var table = InlineArray[Int64, BUCKETS * WIDTH]()
    var statuses = InlineArray[Int64, MAX_OPERATIONS]()
    for position in range(BUCKETS * WIDTH): table[position] = 0
    for operation in range(count):
        let opcode = input[1 + 3 * operation]
        let primary = Int(input[2 + 3 * operation])
        let fingerprint = input[3 + 3 * operation]
        let alternate = primary ^ cf_delta(fingerprint)
        if opcode == 0:
            var empty = -1
            for slot in range(WIDTH):
                if table[primary * WIDTH + slot] == 0: empty = slot; break
            if empty >= 0:
                table[primary * WIDTH + empty] = fingerprint
            else:
                for slot in range(WIDTH):
                    if table[alternate * WIDTH + slot] == 0: empty = slot; break
                if empty >= 0:
                    table[alternate * WIDTH + empty] = fingerprint
                else:
                    var current = primary
                    var pending = fingerprint
                    var placed = False
                    for _ in range(MAX_KICKS):
                        let position = current * WIDTH
                        let evicted = table[position]
                        table[position] = pending
                        pending = evicted
                        current = current ^ cf_delta(pending)
                        for slot in range(WIDTH):
                            if table[current * WIDTH + slot] == 0:
                                table[current * WIDTH + slot] = pending
                                placed = True
                                break
                        if placed: break
                    if not placed: return -3
            statuses[operation] = 1
        elif opcode == 1:
            var found = False
            for order in range(2):
                let bucket = if order == 0: primary else: alternate
                for slot in range(WIDTH):
                    if table[bucket * WIDTH + slot] == fingerprint: found = True
            statuses[operation] = 1 if found else 0
        else:
            var removed = False
            for order in range(2):
                let bucket = if order == 0: primary else: alternate
                for slot in range(WIDTH):
                    let position = bucket * WIDTH + slot
                    if table[position] == fingerprint:
                        table[position] = 0
                        removed = True
                        break
                if removed: break
            statuses[operation] = 1 if removed else 0
    for operation in range(count): cf_write(output, operation, statuses[operation])
    Int64(required)
