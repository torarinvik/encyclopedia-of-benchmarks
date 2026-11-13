from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("weak_stable_matching_ties_incomplete")
fn weak_stable_matching_ties_incomplete(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 73: return -1
    let raw_n = input[0]
    if raw_n < 1 or raw_n > 6: return -1
    let n = Int(raw_n)
    let side = n * n
    if length != c_size_t(1 + 2 * side): return -1
    for man in range(n):
        for woman in range(n):
            let mr = input[1 + man * n + woman]
            let wr = input[1 + side + woman * n + man]
            if mr < 0 or mr > raw_n or wr < 0 or wr > raw_n: return -1
            if (mr > 0) != (wr > 0): return -1

    var choices = InlineArray[Int, 36](fill=0)
    var counts = InlineArray[Int, 6](fill=0)
    for man in range(n):
        for woman in range(n):
            let rank = input[1 + man * n + woman]
            if rank == 0: continue
            var at = counts[man]
            while at > 0:
                let prior = choices[man * 6 + at - 1]
                let prior_rank = input[1 + man * n + prior]
                if prior_rank < rank or (prior_rank == rank and prior < woman): break
                choices[man * 6 + at] = prior
                at -= 1
            choices[man * 6 + at] = woman
            counts[man] += 1

    var man_partner = InlineArray[Int, 6](fill=-1)
    var woman_partner = InlineArray[Int, 6](fill=-1)
    var next_choice = InlineArray[Int, 6](fill=0)
    while True:
        var man = -1
        for candidate in range(n):
            if man_partner[candidate] < 0 and next_choice[candidate] < counts[candidate]:
                man = candidate
                break
        if man < 0: break
        let woman = choices[man * 6 + next_choice[man]]
        next_choice[man] += 1
        let incumbent = woman_partner[woman]
        var accept = incumbent < 0
        if incumbent >= 0:
            let rank = input[1 + side + woman * n + man]
            let old_rank = input[1 + side + woman * n + incumbent]
            accept = rank < old_rank or (rank == old_rank and man < incumbent)
        if accept:
            woman_partner[woman] = man
            man_partner[man] = woman
            if incumbent >= 0: man_partner[incumbent] = -1

    var words = InlineArray[Int64, 13](fill=0)
    var pairs = 0
    for man in range(n):
        if man_partner[man] >= 0:
            words[1 + 2 * pairs] = Int64(man)
            words[2 + 2 * pairs] = Int64(man_partner[man])
            pairs += 1
    words[0] = Int64(pairs)
    let byte_count = 8 * (1 + 2 * pairs)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(byte_count): return -2
    for word in range(1 + 2 * pairs):
        let bits = bitcast[UInt64](words[word])
        for byte in range(8): output[8 * word + byte] = UInt8((bits >> UInt(8 * byte)) & 255)
    return Int64(byte_count)
