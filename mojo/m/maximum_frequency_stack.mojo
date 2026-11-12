from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("maximum_frequency_stack")
fn maximum_frequency_stack(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin],
        capacity: c_size_t) -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 130:
        return -1
    let count = input[0]
    if count < 0 or count > 64 or length != c_size_t(1 + 2 * count):
        return -1
    var frequency = InlineArray[Int32, 17](fill=0)
    var bucket_top = InlineArray[Int32, 65](fill=-1)
    var node_value = InlineArray[Int64, 64](fill=0)
    var node_next = InlineArray[Int32, 64](fill=-1)
    var popped = InlineArray[Int64, 64](fill=0)
    var nodes = 0
    var pop_count = 0
    var position = 1
    var maximum_frequency = 0
    for _ in range(Int(count)):
        let opcode = input[position]
        let argument = input[position + 1]
        position += 2
        if opcode == 0:
            if argument < -8 or argument > 8: return -1
            let index = Int(argument + 8)
            frequency[index] += 1
            let level = Int(frequency[index])
            node_value[nodes] = argument
            node_next[nodes] = bucket_top[level]
            bucket_top[level] = Int32(nodes)
            nodes += 1
            if level > maximum_frequency: maximum_frequency = level
        elif opcode == 1 and argument == 0:
            if maximum_frequency == 0 or bucket_top[maximum_frequency] < 0: return -1
            let node = Int(bucket_top[maximum_frequency])
            bucket_top[maximum_frequency] = node_next[node]
            let value = node_value[node]
            popped[pop_count] = value
            pop_count += 1
            frequency[Int(value + 8)] -= 1
            if bucket_top[maximum_frequency] < 0: maximum_frequency -= 1
        else:
            return -1
    let needed = pop_count * 8
    if needed > 0 and (output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(needed)):
        return -2
    if needed > 0:
        for index in range(pop_count):
            let bits = bitcast[UInt64](popped[index])
            for byte in range(8):
                output[index * 8 + byte] = UInt8((bits >> (byte * 8)) & 255)
    return Int64(needed)
