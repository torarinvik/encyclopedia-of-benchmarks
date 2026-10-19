from std.memory import ImmutAnyOrigin, UnsafePointer

fn prime(p: UInt64) -> Bool:
    if p < 2: return False
    var d: UInt64 = 2
    while d <= p / d:
        if p % d == 0: return False
        d += 1
    return True

@export("largest_power")
fn largest_power(n: UInt64, p: UInt64) abi("C") -> Int64:
    if n > 4294967295 or p > 65535 or not prime(p): return -1
    var q = n; var total: Int64 = 0
    while q != 0: q /= p; total += q.cast[Int64]()
    return total
