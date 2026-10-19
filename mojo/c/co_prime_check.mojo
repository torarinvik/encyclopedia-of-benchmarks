@export("co_prime_check")
fn co_prime_check(first: UInt64, second: UInt64) abi("C") -> Int64:
    if first > 2147483647 or second > 2147483647: return -1
    var a = first
    var b = second
    while b != 0:
        let r = a % b
        a = b
        b = r
    return 1 if a == 1 else 0
