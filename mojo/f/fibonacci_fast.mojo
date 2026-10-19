@export("fibonacci_fast")
fn fibonacci_fast(input: Int64) abi("C") -> Int64:
    if input < 0 or input > 92: return -1
    let n = UInt64(input)
    var bit: UInt64 = 1
    while bit <= n / 2: bit <<= 1
    var current: UInt64 = 0
    var next: UInt64 = 1
    while bit != 0:
        let even = current * (2 * next - current)
        let odd = current * current + next * next
        if (n & bit) != 0:
            current = odd
            next = even + odd
        else:
            current = even
            next = odd
        bit >>= 1
    return Int64(current)
