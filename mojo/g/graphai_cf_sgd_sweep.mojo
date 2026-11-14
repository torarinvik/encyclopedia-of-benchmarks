# Independent bounded GraphAIBench SGD sweep; see package MIT notice.
from std.collections import List
from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("graphai_cf_sgd_sweep")
fn graphai_cf_sgd_sweep(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
                         output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length < 6 or length > 95: return -1
    for i in range(Int(length)):
        if not isfinite(input[i]): return -1
    let uv = input[0]
    let iv = input[1]
    let mv = input[2]
    let kv = input[3]
    if uv < 1.0 or uv > 7.0 or iv < 1.0 or iv > 7.0 or mv < 0.0 or mv > 24.0 or kv < 1.0 or kv > 4.0: return -1
    let users = Int(uv)
    let items = Int(iv)
    let n = users+items
    let m = Int(mv)
    let k = Int(kv)
    if Float64(users) != uv or Float64(items) != iv or Float64(m) != mv or Float64(k) != kv or n > 8: return -1
    let regularization = input[4]
    let step = input[5]
    if regularization < 0.0 or regularization > 1.0 or step < 0.0 or step > 0.01 or length != c_size_t(7+n+2*m+n*k): return -1
    let row_at = 6
    let col_at = row_at+n+1
    let rating_at = col_at+m
    let latent_at = rating_at+m
    var rows = List[Int](capacity=n+1)
    var cols = List[Int](capacity=m)
    for i in range(n+1):
        let value = input[row_at+i]
        if value < 0.0 or value > mv or Float64(Int(value)) != value: return -1
        let row = Int(value)
        if i > 0 and row < rows[i-1]: return -1
        rows.append(row)
    if rows[0] != 0 or rows[n] != m: return -1
    for u in range(users,n):
        if rows[u] != rows[u+1]: return -1
    for e in range(m):
        let value = input[col_at+e]
        if value < uv or value >= Float64(n) or Float64(Int(value)) != value: return -1
        if input[rating_at+e] < -4.0 or input[rating_at+e] > 4.0: return -1
        cols.append(Int(value))
    for i in range(n*k):
        if input[latent_at+i] < -2.0 or input[latent_at+i] > 2.0: return -1
    let required = n*k
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < c_size_t(required): return -2
    var error = List[Float64](capacity=required)
    var staged = List[Float64](capacity=required)
    for _ in range(required): error.append(0.0)
    for u in range(users):
        for e in range(rows[u],rows[u+1]):
            let v = cols[e]
            var estimate = Float64(0.0)
            for j in range(k): estimate += input[latent_at+u*k+j]*input[latent_at+v*k+j]
            let delta = input[rating_at+e]-estimate
            for j in range(k): error[u*k+j] += input[latent_at+v*k+j]*delta
    for i in range(required):
        let old = input[latent_at+i]
        staged.append(old+step*(-regularization*old+error[i]))
    for i in range(required): output[i] = staged[i]
    return Int64(required)
