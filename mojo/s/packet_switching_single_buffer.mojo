from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("packet_switching_single_buffer")
fn packet_switching_single_buffer(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 37: return -1
    let mode = input[0]
    let buffer = input[1]
    let beta = input[2]
    let slots_value = input[3]
    let count_value = input[4]
    if mode < 0 or mode > 2 or buffer < 1 or buffer > 4 or slots_value < 1 or slots_value > 8 or count_value < 0 or count_value > 16 or length != c_size_t(5 + 2 * count_value): return -1
    if (mode == 0 and beta != 0) or (mode != 0 and beta != 15): return -1
    let slots = Int(slots_value)
    let count = Int(count_value)
    var arrival = InlineArray[Int64, 16](fill=0)
    var values = InlineArray[Int64, 16](fill=0)
    var previous: Int64 = -1
    for i in range(count):
        let t = input[5 + 2 * i]
        let value = input[6 + 2 * i]
        if t < 0 or t >= slots_value or t < previous or value < 1 or value > 100: return -1
        arrival[i] = t
        values[i] = value
        previous = t
    var ids = InlineArray[Int64, 4](fill=0)
    var resident_values = InlineArray[Int64, 4](fill=0)
    var resident_count = 0
    var next_packet = 0
    var schedule = InlineArray[Int64, 8](fill=-1)
    for slot in range(slots):
        while next_packet < count and arrival[next_packet] == Int64(slot):
            let value = values[next_packet]
            var evict = resident_count
            if mode != 0:
                for i in range(resident_count):
                    if mode == 1 and 15 * resident_values[i] <= value:
                        evict = i
                        break
                    if mode == 2 and 15 * resident_values[i] < value:
                        if i + 1 == resident_count or resident_values[i] <= resident_values[i + 1]:
                            evict = i
                            break
            if evict == resident_count and resident_count == Int(buffer):
                var lowest = 0
                for i in range(1, resident_count):
                    if resident_values[i] < resident_values[lowest]: lowest = i
                if value > resident_values[lowest]: evict = lowest
            if evict < resident_count:
                for i in range(evict, resident_count - 1):
                    ids[i] = ids[i + 1]
                    resident_values[i] = resident_values[i + 1]
                resident_count -= 1
            if resident_count < Int(buffer):
                ids[resident_count] = Int64(next_packet)
                resident_values[resident_count] = value
                resident_count += 1
            next_packet += 1
        if resident_count > 0:
            schedule[slot] = ids[0]
            for i in range(resident_count - 1):
                ids[i] = ids[i + 1]
                resident_values[i] = resident_values[i + 1]
            resident_count -= 1
    let bytes = 8 * slots
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for slot in range(slots):
        var bits = bitcast[UInt64](schedule[slot])
        for byte in range(8):
            output[8 * slot + byte] = UInt8(bits & 255)
            bits >>= 8
    return Int64(bytes)
