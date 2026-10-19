comptime MAX_UINT53: Int64 = 9007199254740991
@export("uint53_xor")
fn uint53_xor(left: Int64, right: Int64) abi("C") -> Int64:
    if left < 0 or left > MAX_UINT53 or right < 0 or right > MAX_UINT53: return -1
    var a = left; var b = right; var result: Int64 = 0; var place: Int64 = 1
    while a > 0 or b > 0:
        if (a % 2 + b % 2) % 2 == 1: result += place
        a /= 2; b /= 2; place *= 2
    return result
