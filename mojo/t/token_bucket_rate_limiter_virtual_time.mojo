from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

MAX_REQUESTS = 63
MAX_INPUT = 66

@export("token_bucket_rate_limiter_virtual_time")
fn token_bucket_rate_limiter_virtual_time(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > MAX_INPUT:
        return -1
    let capacity = input[0]
    let rate = input[1]
    let q = input[2]
    if capacity < 0 or capacity > 64 or rate < 0 or rate > 32 or q < 0 or q > MAX_REQUESTS or length != c_size_t(3 + q):
        return -1
    for i in range(Int(q)):
        if input[3 + i] < 0 or input[3 + i] > 256:
            return -1

    var tokens = capacity
    var allowed: Int64 = 0
    for i in range(Int(q)):
        tokens = min(capacity, tokens + input[3 + i] * rate)
        if tokens > 0:
            allowed |= Int64(1) << i
            tokens -= 1
    return allowed
