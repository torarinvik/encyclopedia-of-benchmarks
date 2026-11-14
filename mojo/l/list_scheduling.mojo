from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn list_scheduling_store(output: UnsafePointer[UInt8, MutAnyOrigin], slot: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8):
        output[slot * 8 + byte] = UInt8((bits >> (8 * byte)) & 255)

@export("list_scheduling")
fn list_scheduling(
    input: UnsafePointer[Int64, ImmutAnyOrigin],
    input_length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin],
    output_capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or input_length < 3 or input_length > 34:
        return -1
    let machines = input[0]
    let jobs = input[1]
    if machines < 1 or machines > 8 or jobs < 1 or jobs > 32 or input_length != c_size_t(jobs + 2):
        return -1

    var durations = InlineArray[Int64, 32](fill=0)
    for i in range(Int(jobs)):
        let duration = input[i + 2]
        if duration < 1 or duration > 10000:
            return -1
        durations[i] = duration

    let byte_count = 8 * (1 + Int(jobs) + Int(machines))
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < c_size_t(byte_count):
        return -2

    var loads = InlineArray[Int64, 8](fill=0)
    var assignments = InlineArray[Int64, 32](fill=0)
    for i in range(Int(jobs)):
        var best = 0
        for machine in range(1, Int(machines)):
            if loads[machine] < loads[best]:
                best = machine
        assignments[i] = Int64(best)
        loads[best] += durations[i]

    var makespan = loads[0]
    for machine in range(1, Int(machines)):
        if loads[machine] > makespan:
            makespan = loads[machine]
    list_scheduling_store(output, 0, makespan)
    for i in range(Int(jobs)):
        list_scheduling_store(output, 1 + i, assignments[i])
    for machine in range(Int(machines)):
        list_scheduling_store(output, 1 + Int(jobs) + machine, loads[machine])
    return Int64(byte_count)
