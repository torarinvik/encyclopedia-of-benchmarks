from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn server_distance(input: UnsafePointer[Int64, ImmutAnyOrigin], p: Int, k: Int, a: Int, b: Int) -> Int64:
    var left = InlineArray[Int, 3](fill=0)
    var right = InlineArray[Int, 3](fill=0)
    var li = 0
    var ri = 0
    for i in range(p):
        if (a & (1 << i)) != 0:
            left[li] = i
            li += 1
        if (b & (1 << i)) != 0:
            right[ri] = i
            ri += 1
    var best: Int64 = 3001
    for x in range(k):
        for y in range(k):
            for z in range(k):
                if k >= 2 and x == y: continue
                if k == 3 and (x == z or y == z): continue
                var cost = input[3 + left[0] * p + right[x]]
                if k >= 2: cost += input[3 + left[1] * p + right[y]]
                if k == 3: cost += input[3 + left[2] * p + right[z]]
                if cost < best: best = cost
    return best

@export("work_function_k_server")
fn work_function_k_server(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                           output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 50: return -1
    if input[0] < 2 or input[0] > 6 or input[1] < 1 or input[1] > 3 or input[1] > input[0]: return -1
    if input[2] < 0 or input[2] > 8: return -1
    let p = Int(input[0])
    let k = Int(input[1])
    let n = Int(input[2])
    let initial_at = 3 + p * p
    let requests_at = initial_at + k
    if Int(length) != requests_at + n: return -1
    for i in range(p):
        for j in range(p):
            let value = input[3 + i * p + j]
            if value < 0 or value > 1000 or (i == j and value != 0) or (i != j and value == 0): return -1
            if value != input[3 + j * p + i]: return -1
    for i in range(p):
        for j in range(p):
            for z in range(p):
                if input[3 + i * p + j] > input[3 + i * p + z] + input[3 + z * p + j]: return -1
    var initial = 0
    for i in range(k):
        let point = input[initial_at + i]
        if point < 0 or point >= Int64(p): return -1
        let bit = 1 << Int(point)
        if (initial & bit) != 0: return -1
        initial |= bit
    for i in range(n):
        if input[requests_at + i] < 0 or input[requests_at + i] >= Int64(p): return -1
    var configs = InlineArray[Int, 20](fill=0)
    var count = 0
    for mask in range(1 << p):
        var remaining = mask
        var size = 0
        while remaining != 0:
            size += remaining & 1
            remaining >>= 1
        if size == k:
            configs[count] = mask
            count += 1
    var work = InlineArray[Int64, 20](fill=0)
    var next = InlineArray[Int64, 20](fill=0)
    for i in range(count): work[i] = server_distance(input, p, k, initial, configs[i])
    var words = InlineArray[Int64, 26](fill=0)
    words[0] = Int64(n)
    words[1] = Int64(k)
    var current = initial
    for step in range(n):
        let request = Int(input[requests_at + step])
        let request_bit = 1 << request
        for x in range(count):
            var best: Int64 = 9223372036854775807
            for y in range(count):
                if (configs[y] & request_bit) == 0: continue
                best = min(best, work[y] + server_distance(input, p, k, configs[y], configs[x]))
            next[x] = best
        var chosen = current
        if (current & request_bit) == 0:
            var best: Int64 = 9223372036854775807
            for point in range(p):
                let bit = 1 << point
                if (current & bit) == 0: continue
                let candidate = (current ^ bit) | request_bit
                for index in range(count):
                    if configs[index] == candidate:
                        let score = work[index] + input[3 + point * p + request]
                        if score < best:
                            best = score
                            chosen = candidate
                        break
        current = chosen
        var position = 0
        for point in range(p):
            if (current & (1 << point)) != 0:
                words[2 + step * k + position] = Int64(point)
                position += 1
        for i in range(count): work[i] = next[i]
    let word_count = 2 + n * k
    let bytes = 8 * word_count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(word_count):
        var bits = UInt64(words[i])
        for b in range(8):
            output[8 * i + b] = UInt8(bits & 255)
            bits >>= 8
    return Int64(bytes)
