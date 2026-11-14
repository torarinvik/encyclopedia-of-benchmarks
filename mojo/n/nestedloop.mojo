@export("nestedloop")
fn nestedloop(input: Int64) abi("C") -> Int64:
    if input < 0 or input > 15:
        return -1
    let n = Int(input)
    var count: Int64 = 0
    for _ in range(n):
        for _ in range(n):
            for _ in range(n):
                for _ in range(n):
                    for _ in range(n):
                        for _ in range(n):
                            count += 1
    return count
