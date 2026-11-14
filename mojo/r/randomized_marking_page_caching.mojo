# Marking page cache with an explicit deterministic victim-choice tape.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("randomized_marking_page_caching")
fn randomized_marking_page_caching(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                   output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 67: return -1
    let cache = input[0]
    let qv = input[1]
    if cache < 1 or cache > 8 or qv < 0 or qv > 32 or length < c_size_t(3+qv): return -1
    let q = Int(qv)
    let cv = input[2+q]
    if cv < 0 or cv > qv or length != c_size_t(3+qv+cv): return -1
    let choices_count = Int(cv)
    var pages = List[Int](capacity=q)
    var choices = List[Int](capacity=choices_count)
    var hits = List[Int64](capacity=q)
    var victims = List[Int64](capacity=q)
    for i in range(q):
        let page = input[2+i]
        if page < 0 or page >= 16: return -1
        pages.append(Int(page)); hits.append(0); victims.append(-1)
    for i in range(choices_count):
        let choice = input[3+q+i]
        if choice < 0 or choice > 16: return -1
        choices.append(Int(choice))
    var resident = 0
    var marked = 0
    var resident_count = 0
    var choice_at = 0
    var misses = Int64(0)
    for i in range(q):
        let page = pages[i]
        let bit = 1 << page
        if (resident & bit) != 0:
            hits[i] = 1
            marked |= bit
            continue
        misses += 1
        if resident_count == Int(cache):
            var eligible = resident & ~marked
            if eligible == 0:
                marked = 0
                eligible = resident
            if choice_at >= choices_count: return -1
            var choice = choices[choice_at]
            choice_at += 1
            var victim = -1
            for candidate in range(16):
                if (eligible & (1 << candidate)) == 0: continue
                if choice == 0:
                    victim = candidate
                    break
                choice -= 1
            if victim < 0: return -1
            let victim_bit = 1 << victim
            resident &= ~victim_bit
            marked &= ~victim_bit
            resident_count -= 1
            victims[i] = Int64(victim)
        resident |= bit
        marked |= bit
        resident_count += 1
    if choice_at != choices_count: return -1
    var fields = List[Int64](capacity=3+2*q)
    fields.append(misses); fields.append(Int64(resident)); fields.append(Int64(marked))
    for i in range(q): fields.append(hits[i])
    for i in range(q): fields.append(victims[i])
    let bytes = 8*len(fields)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(len(fields)):
        for byte in range(8): output[8*i+byte] = UInt8((fields[i] >> (8*byte)) & 255)
    return Int64(bytes)
