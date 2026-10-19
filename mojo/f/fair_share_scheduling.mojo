from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("fair_share_scheduling")
fn fair_share_scheduling(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 323: return -2
    let nu = values[0]
    let nt = values[1]
    let resources = values[2]
    if nu < 0 or nu > 64 or nt < 0 or nt > 128 or resources < 0 or resources > 1000000 or length != 3 + nu + 2 * nt: return -2
    var ids = InlineArray[Int64, 64](0)
    var weights = InlineArray[Int64, 64](0)
    var order = InlineArray[Int64, 64](0)
    for u in range(nu):
        let id = values[3 + u]
        if id < 0 or id > 63: return -2
        for j in range(u):
            if ids[j] == id: return -2
        ids[u] = id
        order[u] = u
    let task_start = 3 + nu
    for t in range(nt):
        let owner = values[task_start + 2 * t]
        let weight = values[task_start + 2 * t + 1]
        if owner < 0 or owner > 63 or weight < 0 or weight > 1000000: return -2
        for u in range(nu):
            if ids[u] == owner:
                weights[u] += weight
                break
    for i in range(1, nu):
        let key = order[i]
        var j = i
        while j > 0 and ids[order[j - 1]] > ids[key]:
            order[j] = order[j - 1]
            j -= 1
        order[j] = key
    var total: Int64 = 0
    for u in range(nu): total += weights[u]
    let bytes = nu * 24
    if capacity < bytes or (bytes > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()): return -2
    var stage = InlineArray[Int64, 192](0)
    for p in range(nu):
        let u = order[p]
        stage[p * 3] = ids[u]
        stage[p * 3 + 1] = weights[u]
        stage[p * 3 + 2] = 0 if total == 0 else weights[u] * resources / total
    for i in range(nu * 3):
        let bits = UInt64(stage[i])
        for b in range(8): output[i * 8 + b] = UInt8((bits >> (8 * b)) & 255)
    return nu
