@export("find_nth_bit")
fn find_nth_bit(num: UInt64, n: UInt64) abi("C") -> Int64:
    if num > 2147483647 or n < 1 or n > 31: return -1
    let value = Int32(num)
    let shift = Int32(n - 1)
    return Int64((value & (Int32(1) << shift)) >> shift)
