from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("hash_map_hopscotch_hashing")
fn hash_map_hopscotch_hashing(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    let slots = 16
    let neighborhood = 4
    let max_operations = 32
    let max_words = 1 + 3 * max_operations
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(1) or length > c_size_t(max_words):
        return -1
    let count_value = input[0]
    if count_value < 0 or count_value > max_operations: return -1
    let count = Int(count_value)
    if length != c_size_t(1 + 3 * count): return -1

    var known_home = InlineArray[Int8, 64](fill=-1)
    for op in range(count):
        let opcode = input[1 + 3 * op]
        let key = input[2 + 3 * op]
        let home = input[3 + 3 * op]
        if (opcode != 1 and opcode != 2) or key < 0 or key >= 64 or home < 0 or home >= slots:
            return -1
        if known_home[Int(key)] >= 0 and Int64(known_home[Int(key)]) != home: return -1
        known_home[Int(key)] = Int8(home)

    let required = count + 2 * slots
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2

    var keys = InlineArray[Int16, 16](fill=-1)
    var homes = InlineArray[UInt8, 16](fill=0)
    var hops = InlineArray[UInt8, 16](fill=0)
    var statuses = InlineArray[UInt8, 32](fill=0)
    for op in range(count):
        let opcode = Int(input[1 + 3 * op])
        let key = Int(input[2 + 3 * op])
        let home = Int(input[3 + 3 * op])
        if opcode == 2:
            var hit = False
            for offset in range(neighborhood):
                if (hops[home] & (UInt8(1) << offset)) != 0 and keys[(home + offset) % slots] == Int16(key):
                    hit = True
            statuses[op] = if hit: UInt8(1) else: UInt8(0)
            continue
        var duplicate = False
        for offset in range(neighborhood):
            if (hops[home] & (UInt8(1) << offset)) != 0 and keys[(home + offset) % slots] == Int16(key):
                duplicate = True
        if duplicate:
            statuses[op] = 2
            continue

        var hole = -1
        for step in range(slots):
            let candidate = (home + step) % slots
            if keys[candidate] < 0:
                hole = candidate
                break
        if hole < 0:
            statuses[op] = 0
            continue
        var reach = (hole - home + slots) % slots
        var failed = False
        while reach >= neighborhood:
            var shifted = False
            for back in range(1, neighborhood):
                let bucket = (hole - (neighborhood - back) + slots) % slots
                let new_offset = (hole - bucket + slots) % slots
                if (bucket - home + slots) % slots >= reach: continue
                for old_offset in range(new_offset):
                    if (hops[bucket] & (UInt8(1) << old_offset)) == 0: continue
                    let old_slot = (bucket + old_offset) % slots
                    if keys[old_slot] < 0 or Int(homes[old_slot]) != bucket: continue
                    if (old_slot - home + slots) % slots >= reach: continue
                    keys[hole] = keys[old_slot]
                    homes[hole] = homes[old_slot]
                    keys[old_slot] = -1
                    homes[old_slot] = 0
                    hops[bucket] = hops[bucket] ^ (UInt8(1) << old_offset)
                    hops[bucket] = hops[bucket] | (UInt8(1) << new_offset)
                    hole = old_slot
                    reach = (hole - home + slots) % slots
                    shifted = True
                    break
                if shifted: break
            if not shifted:
                failed = True
                break
        if failed:
            statuses[op] = 0
        else:
            keys[hole] = Int16(key)
            homes[hole] = UInt8(home)
            hops[home] = hops[home] | (UInt8(1) << reach)
            statuses[op] = 1

    for op in range(count):
        output[op] = statuses[op]
    for slot in range(slots):
        output[count + slot] = UInt8(0) if keys[slot] < 0 else UInt8(keys[slot] + 1)
        output[count + slots + slot] = hops[slot]
    return Int64(required)
