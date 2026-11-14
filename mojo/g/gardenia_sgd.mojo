# Independent bounded sequential SGD profile; see package LICENSE.txt.
from std.collections import List
from std.ffi import c_size_t
from std.math import isfinite, sqrt
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("gardenia_sgd")
fn gardenia_sgd(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length < 4 or length > 92: return -1
    for i in range(Int(length)):
        if not isfinite(input[i]): return -1
    let uv = input[0]; let iv = input[1]; let mv = input[2]; let kv = input[3]
    if uv < 1.0 or uv > 7.0 or iv < 1.0 or iv > 7.0 or mv < 1.0 or mv > 24.0 or kv < 1.0 or kv > 4.0: return -1
    let users = Int(uv); let items = Int(iv); let ratings = Int(mv); let factors = Int(kv)
    if Float64(users) != uv or Float64(items) != iv or Float64(ratings) != mv or Float64(factors) != kv: return -1
    let vertices = users + items
    if vertices > 8 or length != c_size_t(5 + users + 2 * ratings + vertices * factors): return -1
    let columns = 5 + users
    let rating_start = columns + ratings
    let latent_start = rating_start + ratings
    var rows = List[Int](length=users + 1, fill=0)
    var cols = List[Int](length=ratings, fill=0)
    for i in range(users + 1):
        let value = input[4 + i]
        if value < 0.0 or value > mv: return -1
        rows[i] = Int(value)
        if Float64(rows[i]) != value or (i > 0 and rows[i] < rows[i - 1]): return -1
    if rows[0] != 0 or rows[users] != ratings: return -1
    for i in range(ratings):
        let value = input[columns + i]
        if value < 0.0 or value >= iv: return -1
        cols[i] = Int(value)
        if Float64(cols[i]) != value or input[rating_start + i] < -4.0 or input[rating_start + i] > 4.0: return -1
    var latent = List[Float64](length=vertices * factors, fill=0.0)
    for i in range(vertices * factors):
        latent[i] = input[latent_start + i]
        if latent[i] < 0.0 or latent[i] > 0.1: return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < c_size_t(vertices * factors): return -2
    var errors = List[Float64](length=users, fill=0.0)
    for _ in range(3):
        for u in range(users): errors[u] = 0.0
        for u in range(users):
            for e in range(rows[u], rows[u + 1]):
                let v = users + cols[e]
                var estimate: Float64 = 0.0
                for f in range(factors): estimate += latent[u * factors + f] * latent[v * factors + f]
                let delta = input[rating_start + e] - estimate
                errors[u] += delta * delta
                for f in range(factors):
                    let ui = u * factors + f; let vi = v * factors + f
                    let pu = latent[ui]; let pi = latent[vi]
                    latent[ui] += 0.00000035 * (-0.001 * pu + pi * delta)
                    latent[vi] += 0.00000035 * (-0.001 * pi + pu * delta)
        var total: Float64 = 0.0
        for u in range(users): total += errors[u]
        if sqrt(total / Float64(ratings)) < 0.1: break
    for i in range(vertices * factors): output[i] = latent[i]
    return Int64(vertices * factors)
