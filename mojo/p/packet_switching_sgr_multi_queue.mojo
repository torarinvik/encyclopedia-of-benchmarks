from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("packet_switching_sgr_multi_queue")
fn packet_switching_sgr_multi_queue(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 35: return -1
    let queue_count = input[0]
    let buffer = input[1]
    let slot_count = input[2]
    if queue_count < 2 or queue_count > 4 or buffer < 1 or buffer > 4 or slot_count < 1 or slot_count > 8: return -1
    let queues = Int(queue_count)
    let slots = Int(slot_count)
    if length != c_size_t(3 + queues * slots): return -1
    var load = InlineArray[Int64, 4](fill=0)
    var peak = InlineArray[Int64, 4](fill=0)
    var schedule = InlineArray[Int64, 8](fill=-1)
    for slot in range(slots):
        for queue in range(queues):
            let arrivals = input[3 + slot * queues + queue]
            if arrivals < 0 or arrivals > buffer: return -1
            load[queue] = min(load[queue] + arrivals, buffer)
            peak[queue] = max(peak[queue], load[queue])
        var nonempty = False
        var large = False
        var underfull_peak = False
        for queue in range(queues):
            if load[queue] > 0:
                nonempty = True
                if load[queue] > buffer // 2: large = True
                if peak[queue] < buffer: underfull_peak = True
        if not nonempty:
            for queue in range(queues): peak[queue] = 0
            continue
        let use_history = not large and underfull_peak
        var selected = queues
        var max_load: Int64 = -1
        for queue in range(queues):
            if load[queue] > 0 and (not use_history or peak[queue] < buffer) and load[queue] > max_load:
                selected = queue
                max_load = load[queue]
        schedule[slot] = Int64(selected)
        load[selected] -= 1
        var empty = True
        for queue in range(queues):
            if load[queue] != 0: empty = False
        if empty:
            for queue in range(queues): peak[queue] = 0
    let bytes = 8 * slots
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for slot in range(slots):
        var bits = bitcast[UInt64](schedule[slot])
        for byte in range(8):
            output[8 * slot + byte] = UInt8(bits & 255)
            bits >>= 8
    return Int64(bytes)
