from std.collections import List

@export("binary_palindrome_check")
fn binary_palindrome_check(value: Int64) abi("C") -> Int64:
    if value < -2_147_483_648 or value > 2_147_483_647: return -1
    if value < 0: return 0
    var bits = List[Int](capacity=32); var n = value
    if n == 0: bits.append(0)
    while n > 0: bits.append(Int(n & 1)); n >>= 1
    var left = 0; var right = len(bits) - 1
    while left < right:
        if bits[left] != bits[right]: return 0
        left += 1; right -= 1
    return 1
