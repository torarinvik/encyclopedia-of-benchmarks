from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("manhattan_mst")
fn manhattan_mst(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 65:
        return -1
    let count = input[0]
    if count < 1 or count > 32 or length != c_size_t(1 + 2 * count):
        return -1
    let n = Int(count)
    var x = InlineArray[Int64, 32](fill=0)
    var y = InlineArray[Int64, 32](fill=0)
    for i in range(n):
        let xi = input[1 + 2 * i]
        let yi = input[2 + 2 * i]
        if xi < -1000000 or xi > 1000000 or yi < -1000000 or yi > 1000000:
            return -1
        x[i] = xi
        y[i] = yi
    var selected = InlineArray[Bool, 32](fill=False)
    var best = InlineArray[Int64, 32](fill=4000001)
    best[0] = 0
    var total: Int64 = 0
    for _ in range(n):
        var vertex = n
        var smallest: Int64 = 4000001
        for i in range(n):
            if not selected[i] and best[i] < smallest:
                vertex = i
                smallest = best[i]
        if vertex == n:
            return -1
        selected[vertex] = True
        total += smallest
        for i in range(n):
            if not selected[i]:
                let distance = abs(x[vertex] - x[i]) + abs(y[vertex] - y[i])
                if distance < best[i]:
                    best[i] = distance
    return total
