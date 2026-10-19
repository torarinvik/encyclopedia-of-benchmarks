comptime MAX_UINT53: Int64 = 9007199254740991

@export("uint53_bitwise_or")
fn uint53_bitwise_or(left: Int64, right: Int64) abi("C") -> Int64:
    if left < 0 or left > MAX_UINT53 or right < 0 or right > MAX_UINT53: return -1
    var result: Int64 = 0
    var place: Int64 = 1
    while left > 0 or right > 0:
        if left % 2 == 1 or right % 2 == 1: result += place
        left /= 2; right /= 2; place *= 2
    return result
