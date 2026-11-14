from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn yds_gcd(a: Int64, b: Int64) -> Int64:
    var x = a
    var y = b
    while y != 0:
        let remainder = x % y
        x = y
        y = remainder
    return x

@export("yds_speed_scaling")
fn yds_speed_scaling(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 13: return -1
    let nv = input[0]
    if nv < 1 or nv > 4 or length != c_size_t(1+3*Int(nv)): return -1
    let n = Int(nv)
    var release = List[Int](capacity=n)
    var deadline = List[Int](capacity=n)
    var work = List[Int64](capacity=n)
    var active = List[Bool](capacity=n)
    for i in range(n):
        let r = input[1+3*i]; let d = input[2+3*i]; let w = input[3+3*i]
        if r < 0 or r >= d or d > 8 or w < 1 or w > 8: return -1
        release.append(Int(r)); deadline.append(Int(d)); work.append(w); active.append(True)
    var fields = List[Int64](capacity=19)
    fields.append(0); fields.append(0); fields.append(1)
    var stages = Int64(0)
    var numerator = Int64(0)
    var denominator = Int64(1)
    var remaining = n
    while remaining > 0:
        var best_a = -1
        var best_b = 0
        var best_work = Int64(0)
        var best_duration = Int64(1)
        for a in range(9):
            for b in range(a+1,9):
                var has_release = False
                var has_deadline = False
                var total = Int64(0)
                for j in range(n):
                    if not active[j]: continue
                    if release[j] == a: has_release = True
                    if deadline[j] == b: has_deadline = True
                    if release[j] >= a and deadline[j] <= b: total += work[j]
                if not has_release or not has_deadline or total == 0: continue
                let duration = Int64(b-a)
                if best_a < 0 or total*best_duration > best_work*duration:
                    best_a = a; best_b = b; best_work = total; best_duration = duration
        if best_a < 0: return -1
        var mask = Int64(0)
        for j in range(n):
            if active[j] and release[j] >= best_a and deadline[j] <= best_b: mask |= Int64(1) << j
        fields.append(Int64(best_a)); fields.append(Int64(best_b)); fields.append(best_work); fields.append(mask)
        let term_num = best_work*best_work*best_work
        let term_den = best_duration*best_duration
        let common = yds_gcd(denominator,term_den)
        numerator = numerator*(term_den//common)+term_num*(denominator//common)
        denominator *= term_den//common
        let divisor = yds_gcd(numerator,denominator)
        numerator //= divisor; denominator //= divisor
        for j in range(n):
            if not active[j]: continue
            if (mask & (Int64(1) << j)) != 0:
                active[j] = False
                remaining -= 1
            else:
                if release[j] > best_a and release[j] < best_b: release[j] = best_a
                elif release[j] >= best_b: release[j] -= Int(best_duration)
                if deadline[j] > best_a and deadline[j] < best_b: deadline[j] = best_a
                elif deadline[j] >= best_b: deadline[j] -= Int(best_duration)
        stages += 1
    fields[0] = stages; fields[1] = numerator; fields[2] = denominator
    let bytes = 8*len(fields)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(len(fields)):
        for j in range(8): output[8*i+j] = UInt8((fields[i] >> (8*j)) & 255)
    return Int64(bytes)
