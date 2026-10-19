from std.collections import InlineArray

@export("count_number_of_one_bits")
fn count_number_of_one_bits(number: Int64, method: Int64) abi("C") -> Int64:
    if number < 0 or number > 4294967295 or method < 0 or method > 2: return -1
    var remaining = UInt32(number)
    var count: Int64 = 0
    if method == 0:
        while remaining != 0:
            remaining &= remaining - 1
            count += 1
        return count
    if method == 1:
        while remaining != 0:
            if remaining % 2 == 1: count += 1
            remaining >>= 1
        return count
    var lookup = InlineArray[Int64, 256](0)
    for i in range(1, 256): lookup[i] = lookup[i >> 1] + (i & 1)
    return lookup[remaining & 255] + lookup[(remaining >> 8) & 255] + lookup[(remaining >> 16) & 255] + lookup[(remaining >> 24) & 255]
