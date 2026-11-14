# Minimum-regret stable matching via thresholded deferred acceptance.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("optimal_stable_marriage")
fn optimal_stable_marriage(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                           output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 129: return -1
    let nv = input[0]
    if nv < 0 or nv > 8 or length != c_size_t(1+2*nv*nv): return -1
    let n = Int(nv)
    var preferences = List[Int](capacity=n*n)
    var women_rank = List[Int](capacity=n*n)
    var result = List[Int](capacity=n)
    for _ in range(n*n):
        preferences.append(0)
        women_rank.append(0)
    for _ in range(n): result.append(-1)
    for row in range(2*n):
        var seen = 0
        for rank in range(n):
            let value = input[1+row*n+rank]
            if value < 0 or value >= nv: return -1
            let person = Int(value)
            if (seen & (1 << person)) != 0: return -1
            seen |= 1 << person
            if row < n: preferences[row*n+rank] = person
            else: women_rank[(row-n)*n+person] = rank
    for threshold in range(n):
        var woman_partner = List[Int](capacity=n)
        var man_partner = List[Int](capacity=n)
        var next_rank = List[Int](capacity=n)
        var queue = List[Int](capacity=n*n+n)
        for i in range(n):
            woman_partner.append(-1); man_partner.append(-1); next_rank.append(0); queue.append(i)
        var head = 0
        while head < len(queue):
            let man = queue[head]
            head += 1
            while next_rank[man] < n:
                let rank = next_rank[man]
                next_rank[man] += 1
                let woman = preferences[man*n+rank]
                if rank > threshold or women_rank[woman*n+man] > threshold: continue
                let incumbent = woman_partner[woman]
                if incumbent < 0 or women_rank[woman*n+man] < women_rank[woman*n+incumbent]:
                    woman_partner[woman] = man
                    man_partner[man] = woman
                    if incumbent >= 0:
                        man_partner[incumbent] = -1
                        queue.append(incumbent)
                    break
                queue.append(man)
                break
        var complete = True
        for man in range(n):
            if man_partner[man] < 0: complete = False
        if complete:
            for man in range(n): result[man] = man_partner[man]
            break
    let bytes = 16*n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for man in range(n):
        for byte in range(8):
            output[16*man+byte] = UInt8((Int64(man) >> (8*byte)) & 255)
            output[16*man+8+byte] = UInt8((Int64(result[man]) >> (8*byte)) & 255)
    return Int64(bytes)
