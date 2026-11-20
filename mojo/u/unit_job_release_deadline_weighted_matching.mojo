from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn ujs_assign(job: Int, starts: InlineArray[Int, 32], ends: InlineArray[Int, 32],
              mut slots: InlineArray[Int, 32], mut seen: InlineArray[Bool, 32]) -> Bool:
    for slot in range(starts[job], ends[job] + 1):
        if seen[slot]: continue
        seen[slot] = True
        let old = slots[slot]
        if old < 0 or ujs_assign(old, starts, ends, slots, seen):
            slots[slot] = job
            return True
    return False

@export("unit_job_release_deadline_weighted_matching")
fn unit_job_release_deadline_weighted_matching(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 98: return -1
    if input[0] < 0 or input[0] > 32: return -1
    let n = Int(input[0])
    if length != c_size_t(1 + 3*n): return -1
    var starts = InlineArray[Int, 32](fill=0)
    var ends = InlineArray[Int, 32](fill=0)
    var weights = InlineArray[Int64, 32](fill=0)
    var order = InlineArray[Int, 32](fill=0)
    var slots = InlineArray[Int, 32](fill=-1)
    for i in range(n):
        let r = input[1+3*i]
        let d = input[2+3*i]
        let w = input[3+3*i]
        if r < 0 or d < r or d >= 32 or w < 0 or w > 1000000: return -1
        starts[i] = Int(r)
        ends[i] = Int(d)
        weights[i] = w
        var j = i
        while j > 0 and weights[order[j-1]] < w:
            order[j] = order[j-1]
            j -= 1
        order[j] = i
    var total: Int64 = 0
    for i in range(n):
        var seen = InlineArray[Bool, 32](fill=False)
        let job = order[i]
        if ujs_assign(job, starts, ends, slots, seen): total += weights[job]
    return total
