# Independent bounded facility-location local search; see package attribution.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn objective(input: UnsafePointer[Int64, ImmutAnyOrigin], n: Int, m: Int, mask: Int) -> Int64:
    let q = n+m
    let fee = 2+q*q
    var total = Int64(0)
    for j in range(m):
        if (mask & (1 << j)) != 0: total += input[fee+j]
    for u in range(n):
        var nearest = Int64(1001)
        for j in range(m):
            if (mask & (1 << j)) != 0 and input[2+u*q+n+j] < nearest:
                nearest = input[2+u*q+n+j]
        total += nearest
    return total

fn lex_less(a: Int, b: Int, m: Int) -> Bool:
    var i = 0
    var j = 0
    while True:
        while i < m and (a & (1 << i)) == 0: i += 1
        while j < m and (b & (1 << j)) == 0: j += 1
        if i == m or j == m: return i == m and j != m
        if i != j: return i < j
        i += 1
        j += 1

@export("facility_location_add_delete_swap")
fn facility_location_add_delete_swap(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                     output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 75: return -1
    let nv = input[0]
    let mv = input[1]
    if nv < 1 or nv > 7 or mv < 1 or mv > 7 or nv+mv > 8: return -1
    let n = Int(nv)
    let m = Int(mv)
    let q = n+m
    if length != c_size_t(3+q*q+m): return -1
    for i in range(q):
        for j in range(q):
            let value = input[2+i*q+j]
            if value < 0 or value > 1000 or (i == j and value != 0) or (i != j and value == 0): return -1
            if value != input[2+j*q+i]: return -1
            for k in range(q):
                if value > input[2+i*q+k]+input[2+k*q+j]: return -1
    let fee = 2+q*q
    for j in range(m):
        if input[fee+j] < 0 or input[fee+j] > 1000: return -1
    let raw = input[fee+m]
    if raw <= 0 or raw >= Int64(1 << m): return -1
    var current = Int(raw)
    var current_cost = objective(input,n,m,current)
    for _ in range(1 << m):
        var best = current
        var best_cost = current_cost
        var neighbors = List[Int](capacity=m*m+m)
        for j in range(m):
            let bit = 1 << j
            if (current & bit) == 0:
                neighbors.append(current | bit)
            elif (current & ~bit) != 0:
                neighbors.append(current & ~bit)
                for k in range(m):
                    let other = 1 << k
                    if (current & other) == 0: neighbors.append((current & ~bit) | other)
        for candidate in neighbors:
            let cost = objective(input,n,m,candidate)
            if cost < best_cost or (cost == best_cost and lex_less(candidate,best,m)):
                best = candidate
                best_cost = cost
        if best_cost*10 >= current_cost*9: break
        current = best
        current_cost = best_cost
    var words = List[Int64](capacity=2+m+n)
    var count = 0
    for j in range(m):
        if (current & (1 << j)) != 0: count += 1
    words.append(current_cost)
    words.append(Int64(count))
    for j in range(m):
        if (current & (1 << j)) != 0: words.append(Int64(j))
    for u in range(n):
        var distance = Int64(1001)
        var selected = 0
        for j in range(m):
            if (current & (1 << j)) != 0 and input[2+u*q+n+j] < distance:
                distance = input[2+u*q+n+j]
                selected = j
        words.append(Int64(selected))
    let bytes = 8*len(words)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(len(words)):
        for byte in range(8): output[8*i+byte] = UInt8((words[i] >> (8*byte)) & 255)
    return Int64(bytes)
