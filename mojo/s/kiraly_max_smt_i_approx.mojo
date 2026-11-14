# Bounded Király deferred-acceptance profile; see the package provenance.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("kiraly_max_smt_i_approx")
fn kiraly_max_smt_i_approx(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                            output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 74: return -1
    if input[0] < 1 or input[0] > 6 or input[1] < 1 or input[1] > 6: return -1
    let men = Int(input[0]); let women = Int(input[1])
    if length != c_size_t(2 + 2*men*women): return -1
    var mr = InlineArray[Int, 36](fill=0)
    var wr = InlineArray[Int, 36](fill=0)
    var live = InlineArray[Bool, 36](fill=False)
    var assignment = InlineArray[Int, 6](fill=-1)
    var partner = InlineArray[Int, 6](fill=-1)
    var status = InlineArray[Int, 6](fill=0)
    for m in range(men):
        for w in range(women):
            let a = input[2 + m*women + w]
            let b = input[2 + men*women + w*men + m]
            if a < -1 or a > 5 or b < -1 or b > 5: return -1
            if (a < 0) != (b < 0): return -1
            mr[6*m+w] = Int(a); wr[6*w+m] = Int(b)
            live[6*m+w] = a >= 0
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8*men): return -2
    var steps = 0
    while True:
        steps += 1
        if steps > 121: return -1
        var m = 0
        while m < men and (status[m] == 2 or assignment[m] >= 0): m += 1
        if m == men: break
        var chosen = -1
        for w in range(women):
            if not live[6*m+w]: continue
            if chosen < 0: chosen = w
            else:
                let rank = mr[6*m+w]; let best = mr[6*m+chosen]
                let maiden = partner[w] < 0; let best_maiden = partner[chosen] < 0
                if rank < best or (rank == best and maiden and not best_maiden): chosen = w
        if chosen < 0:
            if status[m] == 0:
                status[m] = 1
                for w in range(women): live[6*m+w] = mr[6*m+w] >= 0
            else: status[m] = 2
            continue
        let incumbent = partner[chosen]
        if incumbent < 0:
            assignment[m] = chosen; partner[chosen] = m
            continue
        var uncertain = False
        if status[incumbent] == 0:
            for w in range(women):
                if live[6*incumbent+w] and w != chosen:
                    let rank = mr[6*incumbent+w]
                    let current = mr[6*incumbent+chosen]
                    if rank < current or (rank == current and partner[w] < 0): uncertain = True
        let new_rank = wr[6*chosen+m]; let old_rank = wr[6*chosen+incumbent]
        let accepts = uncertain or new_rank < old_rank or (new_rank == old_rank and
            (status[m] > status[incumbent] or (status[m] == status[incumbent] and m < incumbent)))
        if accepts:
            assignment[incumbent] = -1
            if not uncertain: live[6*incumbent+chosen] = False
            assignment[m] = chosen; partner[chosen] = m
        else: live[6*m+chosen] = False
    for m in range(men):
        if assignment[m] < 0:
            for byte in range(8): output[8*m+byte] = 255
        else:
            output[8*m] = UInt8(assignment[m])
            for byte in range(1, 8): output[8*m+byte] = 0
    return Int64(8*men)
