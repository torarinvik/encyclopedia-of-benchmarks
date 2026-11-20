from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

comptime ARENA = 256
comptime MAX_ORDER = 8
comptime MAX_OPS = 64
comptime MAX_IDS = 32
comptime MAX_INPUT_WORDS = 194
comptime MAX_OUTPUT_WORDS = 3 * MAX_OPS + 1 + 2 * ARENA

@export("buddy_system_allocator")
fn buddy_system_allocator(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                          output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_INPUT_WORDS: return -1
    let raw_count = input[0]
    if raw_count < 0 or raw_count > MAX_OPS or length != c_size_t(1 + 3 * raw_count): return -1
    let count = Int(raw_count)

    var free_blocks = List[Bool](capacity=(MAX_ORDER + 1) * ARENA)
    var active = List[Bool](capacity=MAX_IDS)
    var allocation_base = List[Int](capacity=MAX_IDS)
    var allocation_order = List[Int](capacity=MAX_IDS)
    for _ in range((MAX_ORDER + 1) * ARENA): free_blocks.append(False)
    for _ in range(MAX_IDS):
        active.append(False); allocation_base.append(0); allocation_order.append(0)
    free_blocks[MAX_ORDER * ARENA] = True
    var staged = List[Int64](capacity=MAX_OUTPUT_WORDS)

    for i in range(count):
        let opcode = input[1 + 3 * i]
        let raw_id = input[2 + 3 * i]
        let argument = input[3 + 3 * i]
        if raw_id < 0 or raw_id >= MAX_IDS: return -1
        let id = Int(raw_id)
        if opcode == 0:
            if argument < 1 or argument > ARENA or active[id]: return -1
            var target = 0
            var rounded = 1
            while rounded < Int(argument):
                rounded *= 2
                target += 1
            var found_order = MAX_ORDER + 1
            var found_base = ARENA
            for order in range(target, MAX_ORDER + 1):
                let block_size = 1 << order
                for base in range(0, ARENA - block_size + 1, block_size):
                    if free_blocks[order * ARENA + base]:
                        found_order = order
                        found_base = base
                        break
                if found_order <= MAX_ORDER: break
            if found_order > MAX_ORDER:
                staged.append(0); staged.append(-1); staged.append(0)
                continue
            free_blocks[found_order * ARENA + found_base] = False
            while found_order > target:
                found_order -= 1
                let half = 1 << found_order
                free_blocks[found_order * ARENA + found_base + half] = True
            active[id] = True
            allocation_base[id] = found_base
            allocation_order[id] = target
            staged.append(1); staged.append(Int64(found_base)); staged.append(Int64(1 << target))
        elif opcode == 1:
            if argument != 0 or not active[id]: return -1
            let original_base = allocation_base[id]
            let original_order = allocation_order[id]
            let original_size = 1 << original_order
            active[id] = False
            var base = original_base
            var order = original_order
            while order < MAX_ORDER:
                let buddy = base ^ (1 << order)
                if not free_blocks[order * ARENA + buddy]: break
                free_blocks[order * ARENA + buddy] = False
                if buddy < base: base = buddy
                order += 1
            free_blocks[order * ARENA + base] = True
            staged.append(1); staged.append(Int64(original_base)); staged.append(Int64(original_size))
        else: return -1

    let count_index = len(staged)
    staged.append(0)
    var free_count = 0
    for base in range(ARENA):
        for order in range(MAX_ORDER, -1, -1):
            if free_blocks[order * ARENA + base]:
                free_count += 1
                staged.append(Int64(base)); staged.append(Int64(1 << order))
                break
    staged[count_index] = Int64(free_count)
    let required = len(staged) * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required): return -2
    for i in range(len(staged)):
        let bits = bitcast[UInt64](staged[i])
        for byte in range(8): output[8 * i + byte] = UInt8((bits >> UInt(8 * byte)) & 255)
    return Int64(required)
