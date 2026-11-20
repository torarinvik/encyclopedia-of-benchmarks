from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("packet_switching_random_schedule")
fn packet_switching_random_schedule(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 68: return -1
    let m_value = input[0]
    let b_value = input[1]
    let t_value = input[2]
    if m_value < 2 or m_value > 4 or b_value < 1 or b_value > 4 or t_value < 1 or t_value > 8: return -1
    let m = Int(m_value)
    let b = Int(b_value)
    let slots = Int(t_value)
    let cells = m * slots
    if length != c_size_t(3 + 2 * cells): return -1
    for cell in range(cells):
        let flag = input[3 + cell]
        let priority = input[3 + cells + cell]
        if flag < 0 or flag > 1 or priority < 0 or priority > 4294967295: return -1
    var load = InlineArray[Int, 4](fill=0)
    var count = InlineArray[Int, 4](fill=0)
    var priorities = InlineArray[Int64, 16](fill=0)
    var marked = InlineArray[Bool, 16](fill=False)
    var trace = InlineArray[Int64, 8](fill=-1)
    for slot in range(slots):
        for queue in range(m):
            let cell = slot * m + queue
            if input[3 + cell] != 0 and load[queue] < b:
                let base = queue * 4
                if count[queue] == b:
                    for index in range(1, count[queue]):
                        priorities[base + index - 1] = priorities[base + index]
                        marked[base + index - 1] = marked[base + index]
                    count[queue] -= 1
                priorities[base + count[queue]] = input[3 + cells + cell]
                marked[base + count[queue]] = False
                count[queue] += 1
                load[queue] += 1
        var best_queue = m
        var best_index = 0
        var best_priority: Int64 = -1
        for queue in range(m):
            let base = queue * 4
            for index in range(count[queue]):
                if not marked[base + index] and (best_queue == m or priorities[base + index] > best_priority):
                    best_queue = queue
                    best_index = base + index
                    best_priority = priorities[base + index]
        if best_queue != m:
            marked[best_index] = True
        else:
            for queue in range(m):
                if load[queue] > 0:
                    best_queue = queue
                    break
        if best_queue != m:
            trace[slot] = Int64(best_queue)
            load[best_queue] -= 1
    let output_bytes = 8 * slots
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes): return -2
    for slot in range(slots):
        var bits = bitcast[UInt64](trace[slot])
        for byte in range(8):
            output[8 * slot + byte] = UInt8(bits & 255)
            bits >>= 8
    return Int64(output_bytes)
