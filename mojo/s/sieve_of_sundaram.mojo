from std.collections import InlineArray

@export("sieve_of_sundaram")
fn sieve_of_sundaram(limit: Int64) abi("C") -> Int64:
    if limit < 0 or limit > 4096:
        return -1
    if limit < 2:
        return 0

    let max_index = Int((limit - 1) // 2)
    var composite = InlineArray[Bool, 2048]()
    var i = 1
    while 2 * i * (i + 1) <= max_index:
        var j = i
        while True:
            let index = i + j + 2 * i * j
            if index > max_index:
                break
            composite[index] = True
            j += 1
        i += 1

    var count = 1
    for index in range(1, max_index + 1):
        if not composite[index]:
            count += 1
    return Int64(count)
