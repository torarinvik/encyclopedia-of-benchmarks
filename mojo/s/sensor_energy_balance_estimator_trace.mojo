from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn sensor_gcd(mut a: Int64, mut b: Int64) -> Int64:
    while b != 0:
        let remainder = a % b
        a = b
        b = remainder
    return a

@export("sensor_energy_balance_estimator_trace")
fn sensor_energy_balance_estimator_trace(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin],
        capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 82: return -1
    let n0 = input[0]; let h0 = input[1]
    if n0 < 1 or n0 > 8 or h0 < 1 or h0 > 8: return -1
    let n = Int(n0); let h = Int(h0)
    if length != c_size_t(2 + n + h + n * h): return -1
    var state = List[Int64](length=n, fill=0)
    var total = Int64(0)
    for i in range(n):
        let value = input[2 + i]
        if value < 0 or value > 1_000_000: return -1
        state[i] = value
        total += value
    if total != 1_000_000: return -1
    let path_at = 2 + n
    let full = Int64((1 << n) - 1)
    for t in range(h):
        let mask = input[path_at + t]
        if mask <= 0 or mask > full: return -1
    var lcm = Int64(1)
    for t in range(2, h + 1):
        lcm = (lcm // sensor_gcd(lcm, Int64(t))) * Int64(t)
    let q = 1_000_000 * lcm
    let draw_at = path_at + h
    for i in range(n * h):
        let draw = input[draw_at + i]
        if draw < 0 or draw >= q: return -1
    for i in range(n): state[i] *= lcm
    for t in range(h):
        let delta = q // Int64(t + 1)
        let mask = input[path_at + t]
        for i in range(n):
            let draw = input[draw_at + t * n + i]
            var sampled = Int64(0)
            if draw < state[i]: sampled = 1
            let observed = (mask >> i) & 1
            let updated = state[i] + (observed - sampled) * delta
            if updated < 0 or updated > q: return -1
            state[i] = updated
    let bytes = 8 * (n + 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(n + 1):
        var value = q
        if i > 0: value = state[i - 1]
        for byte in range(8): output[8 * i + byte] = UInt8((value >> (8 * byte)) & 255)
    return Int64(bytes)
