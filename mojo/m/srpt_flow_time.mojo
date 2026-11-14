from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn srpt_store(output: UnsafePointer[UInt8, MutAnyOrigin], slot: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8):
        output[8 * slot + byte] = UInt8((bits >> (8 * byte)) & 255)

@export("srpt_flow_time")
fn srpt_flow_time(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 26:
        return -1
    let machines = input[0]
    let jobs = input[1]
    if machines < 1 or machines > 4 or jobs < 1 or jobs > 12 or length != c_size_t(2 + 2 * jobs):
        return -1
    let n = Int(jobs)
    var release = InlineArray[Int64, 12](fill=0)
    var remaining = InlineArray[Int64, 12](fill=0)
    var completion = InlineArray[Int64, 12](fill=0)
    for job in range(n):
        let r = input[2 + 2 * job]
        let p = input[3 + 2 * job]
        if r < 0 or r > 50 or p < 1 or p > 10:
            return -1
        release[job] = r
        remaining[job] = p
    let bytes = 8 * (n + 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes):
        return -2
    var time: Int64 = 0
    var done = 0
    while done < n:
        var chosen = InlineArray[Bool, 12](fill=False)
        var selected = InlineArray[Int, 4](fill=0)
        var selected_count = 0
        for _ in range(Int(machines)):
            var best = n
            for job in range(n):
                if not chosen[job] and remaining[job] > 0 and release[job] <= time:
                    if best == n or remaining[job] < remaining[best]:
                        best = job
            if best == n:
                break
            chosen[best] = True
            selected[selected_count] = best
            selected_count += 1
        if selected_count == 0:
            var next_release: Int64 = 51
            for job in range(n):
                if remaining[job] > 0 and release[job] < next_release:
                    next_release = release[job]
            time = next_release
        else:
            time += 1
            for i in range(selected_count):
                let job = selected[i]
                remaining[job] -= 1
                if remaining[job] == 0:
                    completion[job] = time
                    done += 1
    var total: Int64 = 0
    for job in range(n):
        total += completion[job] - release[job]
    srpt_store(output, 0, total)
    for job in range(n):
        srpt_store(output, job + 1, completion[job])
    return Int64(bytes)
