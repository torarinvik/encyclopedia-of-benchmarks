from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("hospitals_residents_rgs")
fn hospitals_residents_rgs(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 7 or length > 154: return -1
    let r0 = input[0]; let h0 = input[1]
    if r0 < 1 or r0 > 8 or h0 < 1 or h0 > 8: return -1
    let r = Int(r0); let h = Int(h0)
    if length != c_size_t(2 + 2 * h + r + 2 * r * h): return -1
    let rlen = 2 + h
    let rpref = rlen + r
    let hlen = rpref + r * h
    let hpref = hlen + h
    var ranks = List[Int64](length=h * r, fill=-1)
    for hospital in range(h):
        if input[2 + hospital] < 1 or input[2 + hospital] > r0 or input[hlen + hospital] < 0 or input[hlen + hospital] > r0: return -1
    for resident in range(r):
        let count = input[rlen + resident]
        if count < 0 or count > h0: return -1
        var seen = List[Bool](length=h, fill=False)
        for slot in range(h):
            let value = input[rpref + resident * h + slot]
            if slot < Int(count):
                if value < 0 or value >= h0: return -1
                if seen[Int(value)]: return -1
                seen[Int(value)] = True
            elif value != -1: return -1
    for hospital in range(h):
        for slot in range(r):
            let value = input[hpref + hospital * r + slot]
            if slot < Int(input[hlen + hospital]):
                if value < 0 or value >= r0: return -1
                let index = hospital * r + Int(value)
                if ranks[index] >= 0: return -1
                ranks[index] = Int64(slot)
            elif value != -1: return -1
    for resident in range(r):
        for hospital in range(h):
            var accepted = False
            for slot in range(Int(input[rlen + resident])):
                if input[rpref + resident * h + slot] == Int64(hospital): accepted = True
            if accepted != (ranks[hospital * r + resident] >= 0): return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8 * r): return -2
    var assignment = List[Int64](length=r, fill=-1)
    var next_choice = List[Int](length=r, fill=0)
    var occupancy = List[Int](length=h, fill=0)
    while True:
        var proposer = -1
        for resident in range(r):
            if assignment[resident] == -1 and next_choice[resident] < Int(input[rlen + resident]):
                proposer = resident
                break
        if proposer < 0: break
        let hospital = Int(input[rpref + proposer * h + next_choice[proposer]])
        next_choice[proposer] += 1
        if occupancy[hospital] < Int(input[2 + hospital]):
            assignment[proposer] = Int64(hospital)
            occupancy[hospital] += 1
        else:
            var worst = -1
            for resident in range(r):
                if assignment[resident] == Int64(hospital):
                    if worst < 0:
                        worst = resident
                    elif ranks[hospital * r + resident] > ranks[hospital * r + worst]:
                        worst = resident
            if worst < 0: return -1
            if ranks[hospital * r + proposer] < ranks[hospital * r + worst]:
                assignment[worst] = -1
                assignment[proposer] = Int64(hospital)
    for i in range(r):
        for byte in range(8): output[8 * i + byte] = UInt8((assignment[i] >> (8 * byte)) & 255)
    return Int64(8 * r)
