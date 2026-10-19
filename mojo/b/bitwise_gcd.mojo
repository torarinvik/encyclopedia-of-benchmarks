@export("bitwise_gcd")
fn bitwise_gcd(left: UInt64, right: UInt64) abi("C") -> Int64:
    if left == 0: return Int64(right)
    if right == 0: return Int64(left)
    var a = left; var b = right; var shift = 0
    while ((a | b) & 1) == 0: a >>= 1; b >>= 1; shift += 1
    while (a & 1) == 0: a >>= 1
    while b != 0:
        while (b & 1) == 0: b >>= 1
        if a > b: let t = a; a = b; b = t
        b -= a
    return Int64(a << shift)
