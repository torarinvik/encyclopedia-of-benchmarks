# Independent class-W NAS Parallel Benchmarks 3.3 integer-sort profile.
from std.collections import List
from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

fn npb_is_rank(iteration: Int, mut keys: List[Int], mut scattered: List[Int],
        mut histogram: List[Int], mut buckets: List[Int], mut positions: List[Int], mut partial: List[Int]):
    keys[iteration] = iteration
    keys[iteration+10] = 65536-iteration
    for i in range(1024): buckets[i] = 0
    for key in keys: buckets[key >> 6] += 1
    positions[0] = 0
    for i in range(1,1024): positions[i] = positions[i-1]+buckets[i-1]
    for key in keys:
        let bucket = key >> 6
        scattered[positions[bucket]] = key
        positions[bucket] += 1
    for i in range(65536): histogram[i] = 0
    for key in scattered: histogram[key] += 1
    for i in range(1,65536): histogram[i] += histogram[i-1]
    var indices = List[Int](capacity=5)
    indices.append(357773); indices.append(934767); indices.append(875723); indices.append(898999); indices.append(404505)
    for i in range(5):
        let key = keys[indices[i]]
        partial[i] = 0
        if key > 0: partial[i] = histogram[key-1]

fn npb_is_decimal(mut bytes: List[UInt8], value: Int):
    var digits = List[UInt8](capacity=10)
    var remaining = value
    while True:
        digits.append(UInt8(48+remaining%10))
        remaining //= 10
        if remaining == 0: break
    for i in range(len(digits)): bytes.append(digits[len(digits)-1-i])

@export("npb_is")
fn npb_is(pass_count: Int64, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if pass_count < 1 or pass_count > 10: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin](): return -2
    let count = 1048576
    var keys = List[Int](length=count, fill=0)
    var scattered = List[Int](length=count, fill=0)
    var histogram = List[Int](length=65536, fill=0)
    var buckets = List[Int](length=1024, fill=0)
    var positions = List[Int](length=1024, fill=0)
    var partial = List[Int](length=5, fill=0)
    var state = UInt64(314159265)
    let mask23 = UInt64((1 << 23)-1)
    let mask46 = (UInt64(1) << 46)-1
    let high = UInt64(1220703125) >> 23
    let low = UInt64(1220703125) & mask23
    for i in range(count):
        var sum = UInt64(0)
        for _ in range(4):
            let upper = state >> 23
            let lower = state & mask23
            let middle = (high*lower+low*upper) & mask23
            state = ((middle << 23)+low*lower) & mask46
            sum += state
        keys[i] = Int(sum >> 32)
    npb_is_rank(1,keys,scattered,histogram,buckets,positions,partial)
    var baseline = List[Int](capacity=5)
    baseline.append(1249); baseline.append(11698); baseline.append(1039987); baseline.append(1043896); baseline.append(1048018)
    var staged = List[UInt8](capacity=353)
    var passed = 0
    for iteration in range(1,Int(pass_count)+1):
        npb_is_rank(iteration,keys,scattered,histogram,buckets,positions,partial)
        for i in range(5):
            var expected = baseline[i]-iteration
            if i < 2: expected = baseline[i]+iteration-2
            if partial[i] == expected: passed += 1
            npb_is_decimal(staged,partial[i])
            if i < 4: staged.append(44)
        staged.append(10)
    for key in scattered:
        histogram[key] -= 1
        keys[histogram[key]] = key
    var ordered = True
    for i in range(1,count):
        if keys[i-1] > keys[i]: ordered = False
    if ordered: passed += 1
    if passed != 5*Int(pass_count)+1: passed = 0
    npb_is_decimal(staged,passed)
    staged.append(10)
    if capacity < c_size_t(len(staged)): return -2
    for i in range(len(staged)): output[i] = staged[i]
    return Int64(len(staged))
