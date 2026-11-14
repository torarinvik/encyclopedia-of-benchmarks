from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn lpt_store(output: UnsafePointer[UInt8, MutAnyOrigin], slot: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8):
        output[slot * 8 + byte] = UInt8((bits >> (8 * byte)) & 255)

@export("max_minimum_machine_load_lpt")
fn max_minimum_machine_load_lpt(
    input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin],
    capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 18:
        return -1
    let job_count = input[0]
    let machine_count = input[1]
    if job_count < 1 or job_count > 16 or machine_count < 1 or machine_count > 4 or length != c_size_t(job_count + 2):
        return -1
    let n = Int(job_count)
    let m = Int(machine_count)
    var durations = InlineArray[Int64, 16](fill=0)
    var order = InlineArray[Int, 16](fill=0)
    for job in range(n):
        let duration = input[job + 2]
        if duration < 1 or duration > 100:
            return -1
        durations[job] = duration
        order[job] = job
    let bytes = 8 * (1 + n + m)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes):
        return -2

    # Stable insertion sorting preserves ascending job IDs for equal durations.
    for i in range(1, n):
        let job = order[i]
        var position = i
        while position > 0 and durations[job] > durations[order[position - 1]]:
            order[position] = order[position - 1]
            position -= 1
        order[position] = job
    var loads = InlineArray[Int64, 4](fill=0)
    var assigned = InlineArray[Int64, 16](fill=0)
    for i in range(n):
        let job = order[i]
        var best = 0
        for machine in range(1, m):
            if loads[machine] < loads[best]:
                best = machine
        assigned[job] = Int64(best)
        loads[best] += durations[job]
    var minimum = loads[0]
    for machine in range(1, m):
        if loads[machine] < minimum:
            minimum = loads[machine]
    lpt_store(output, 0, minimum)
    for job in range(n):
        lpt_store(output, 1 + job, assigned[job])
    for machine in range(m):
        lpt_store(output, 1 + n + machine, loads[machine])
    return Int64(bytes)
