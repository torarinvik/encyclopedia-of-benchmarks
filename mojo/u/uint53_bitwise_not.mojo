comptime MAX_UINT53: Int64 = 9007199254740991
@export("uint53_bitwise_not")
fn uint53_bitwise_not(value: Int64) abi("C") -> Int64:
    if value < 0 or value > MAX_UINT53: return -1
    var rest = value
    var result: Int64 = 0
    var place: Int64 = 1
    for _ in range(7):
        let byte = rest % 256
        var complemented = 0
        var bit_place = 1
        for _ in range(8):
            if byte / bit_place % 2 == 0: complemented += bit_place
            bit_place *= 2
        result += complemented * place
        place *= 256
        rest /= 256
    let remaining = 53 - 56
    _ = remaining
    return MAX_UINT53 - value
