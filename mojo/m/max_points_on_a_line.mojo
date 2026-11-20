from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_N = 16
comptime MAX_INPUT = 34
comptime TABLE_SIZE = 32

fn gcd_positive(a_value: Int, b_value: Int) -> Int:
    var a = a_value
    var b = b_value
    while b != 0:
        let remainder = a % b
        a = b
        b = remainder
    return a

@export("max_points_on_a_line")
fn max_points_on_a_line(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(3) or length > c_size_t(MAX_INPUT):
        return -1
    let n = Int(input[0])
    if n < 1 or n > MAX_N or Int(length) != 1 + 2 * n:
        return -1
    var x = InlineArray[Int, 16](fill=0)
    var y = InlineArray[Int, 16](fill=0)
    for i in range(n):
        let xv = Int(input[1 + 2 * i])
        let yv = Int(input[2 + 2 * i])
        if xv < -100 or xv > 100 or yv < -100 or yv > 100:
            return -1
        for j in range(i):
            if x[j] == xv and y[j] == yv:
                return -1
        x[i] = xv
        y[i] = yv
    if n == 1:
        return 1
    var answer = 2
    for anchor in range(n):
        var keys = InlineArray[Int, 32](fill=-1)
        var counts = InlineArray[Int, 32](fill=0)
        var best = 0
        for other in range(n):
            if other == anchor:
                continue
            var dx = x[other] - x[anchor]
            var dy = y[other] - y[anchor]
            let divisor = gcd_positive(abs(dx), abs(dy))
            dx //= divisor
            dy //= divisor
            if dx < 0 or (dx == 0 and dy < 0):
                dx = -dx
                dy = -dy
            let direction_key = dx * 401 + dy + 200
            var slot = direction_key % TABLE_SIZE
            while keys[slot] != -1 and keys[slot] != direction_key:
                slot = (slot + 1) % TABLE_SIZE
            if keys[slot] == -1:
                keys[slot] = direction_key
            counts[slot] += 1
            best = max(best, counts[slot])
        answer = max(answer, best + 1)
    return Int64(answer)
