from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

const MAX_OPS: Int = 40
const MAX_WORDS: Int = 82
const KEY_COUNT: Int = 256

@export("extendible_hashing_trace")
fn extendible_hashing_trace(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_WORDS:
        return -1
    let q_value = input[0]
    if q_value < 0 or q_value > MAX_OPS or Int(length) != 1 + 2 * Int(q_value):
        return -1
    let q = Int(q_value)
    for i in range(q):
        let opcode = input[1 + 2 * i]
        let key = input[2 + 2 * i]
        if opcode < 0 or opcode > 2 or key < 0 or key > 255:
            return -1

    var directory = List[UInt8](length=KEY_COUNT, fill=0)
    var keys = List[UInt8](length=2 * KEY_COUNT, fill=0)
    var counts = List[UInt8](length=KEY_COUNT, fill=0)
    var depths = List[UInt8](length=KEY_COUNT, fill=0)
    var active = List[Bool](length=KEY_COUNT, fill=False)
    directory[0] = 0; directory[1] = 1
    active[0] = True; active[1] = True
    depths[0] = 1; depths[1] = 1
    var gd = 1
    var high_depth = 1
    var bucket_count = 2
    var live = 0
    var successes: UInt64 = 0

    for i in range(q):
        let opcode = Int(input[1 + 2 * i])
        let key = Int(input[2 + 2 * i])
        var bucket = Int(directory[key & ((1 << gd) - 1)])
        var slot = -1
        for j in range(Int(counts[bucket])):
            if Int(keys[2 * bucket + j]) == key:
                slot = j
                break
        var success: UInt64 = 0
        if opcode == 0 and slot < 0:
            while Int(counts[bucket]) == 2:
                let depth = Int(depths[bucket])
                if depth >= 8:
                    break
                if depth == gd:
                    let old_size = 1 << gd
                    for j in range(old_size):
                        directory[j + old_size] = directory[j]
                    gd += 1
                    if gd > high_depth:
                        high_depth = gd
                var fresh = 0
                while fresh < KEY_COUNT and active[fresh]:
                    fresh += 1
                if fresh == KEY_COUNT:
                    break
                active[fresh] = True
                depths[bucket] = UInt8(depth + 1)
                depths[fresh] = UInt8(depth + 1)
                let old_count = Int(counts[bucket])
                let old0 = keys[2 * bucket]
                let old1 = keys[2 * bucket + 1]
                counts[bucket] = 0; counts[fresh] = 0
                keys[2 * bucket] = 0; keys[2 * bucket + 1] = 0
                keys[2 * fresh] = 0; keys[2 * fresh + 1] = 0
                let bit = 1 << depth
                let size = 1 << gd
                for j in range(size):
                    if Int(directory[j]) == bucket and (j & bit) != 0:
                        directory[j] = UInt8(fresh)
                for j in range(old_count):
                    let value = Int(old0) if j == 0 else Int(old1)
                    let target = fresh if (value & bit) != 0 else bucket
                    keys[2 * target + Int(counts[target])] = UInt8(value)
                    counts[target] += 1
                bucket = Int(directory[key & ((1 << gd) - 1)])
            if Int(counts[bucket]) < 2:
                keys[2 * bucket + Int(counts[bucket])] = UInt8(key)
                counts[bucket] += 1
                live += 1
                success = 1
        elif opcode == 1 and slot >= 0:
            counts[bucket] -= 1
            let last = Int(counts[bucket])
            keys[2 * bucket + slot] = keys[2 * bucket + last]
            keys[2 * bucket + last] = 0
            live -= 1
            success = 1
            while Int(depths[bucket]) > 1:
                let depth = Int(depths[bucket])
                let size = 1 << gd
                var representative = -1
                for j in range(size):
                    if Int(directory[j]) == bucket:
                        representative = j
                        break
                if representative < 0:
                    break
                let prefix = representative & ((1 << depth) - 1)
                let buddy_prefix = prefix ^ (1 << (depth - 1))
                let buddy = Int(directory[buddy_prefix])
                if buddy == bucket or not active[buddy] or Int(depths[buddy]) != depth or Int(counts[bucket]) + Int(counts[buddy]) > 2:
                    break
                let keep = buddy if buddy_prefix < prefix else bucket
                let drop = bucket if keep == buddy else buddy
                let keep_count = Int(counts[keep])
                let drop_count = Int(counts[drop])
                for j in range(drop_count):
                    keys[2 * keep + keep_count + j] = keys[2 * drop + j]
                counts[keep] += counts[drop]
                counts[drop] = 0
                keys[2 * drop] = 0; keys[2 * drop + 1] = 0
                depths[keep] = UInt8(depth - 1)
                active[drop] = False
                for j in range(size):
                    if Int(directory[j]) == drop:
                        directory[j] = UInt8(keep)
                bucket_count -= 1
                bucket = keep
            while gd > 1:
                let half = 1 << (gd - 1)
                var mirrors = True
                for j in range(half):
                    if directory[j] != directory[j + half]:
                        mirrors = False
                        break
                if not mirrors:
                    break
                gd -= 1
        elif opcode == 2 and slot >= 0:
            success = 1
        successes = (successes << 1) | success

    return Int64(successes | (UInt64(bucket_count) << 40) | (UInt64(gd) << 49) |
                 (UInt64(high_depth) << 53) | (UInt64(live) << 57))
