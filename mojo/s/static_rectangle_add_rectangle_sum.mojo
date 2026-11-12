from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 32
comptime MAX_Q = 32
comptime MAX_COORDS = 128
comptime STRIDE = 129
comptime MODULUS: Int64 = 998244353
comptime MAX_INPUT = 291

fn sras_lower(values: UnsafePointer[Int64, ImmutAnyOrigin], count: Int, target: Int64) -> Int:
    var left = 0
    var right = count
    while left < right:
        let middle = left + (right - left) // 2
        if values[middle] < target:
            left = middle + 1
        else:
            right = middle
    return left

fn sras_sort_unique(values: UnsafePointer[Int64, MutAnyOrigin], count: Int) -> Int:
    for index in range(1, count):
        let value = values[index]
        var position = index
        while position > 0 and values[position - 1] > value:
            values[position] = values[position - 1]
            position -= 1
        values[position] = value
    var unique_count = 0
    for index in range(count):
        if unique_count == 0 or values[index] != values[unique_count - 1]:
            values[unique_count] = values[index]
            unique_count += 1
    return unique_count

fn sras_store(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (8 * byte)) & UInt64(255))

@export("static_rectangle_add_rectangle_sum")
fn static_rectangle_add_rectangle_sum(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(MAX_INPUT):
        return -1
    let n_value = input[0]
    let q_value = input[1]
    if n_value < 1 or n_value > MAX_N or q_value < 0 or q_value > MAX_Q:
        return -1
    let n = Int(n_value)
    let q = Int(q_value)
    if length != c_size_t(2 + 5 * n + 4 * q):
        return -1

    var updates = InlineArray[Int64, 5 * MAX_N]()
    var queries = InlineArray[Int64, 4 * MAX_Q]()
    var xs = InlineArray[Int64, MAX_COORDS]()
    var ys = InlineArray[Int64, MAX_COORDS]()
    var nx = 0
    var ny = 0
    var offset = 2
    for index in range(n):
        let at = index * 5
        for field in range(5):
            updates[at + field] = input[offset + field]
        let left = updates[at]
        let down = updates[at + 1]
        let right = updates[at + 2]
        let up = updates[at + 3]
        let weight = updates[at + 4]
        if left < 0 or left >= right or right > 1_000_000 or down < 0 or down >= up or up > 1_000_000 or weight < 0 or weight >= MODULUS:
            return -1
        xs[nx] = left
        xs[nx + 1] = right
        ys[ny] = down
        ys[ny + 1] = up
        nx += 2
        ny += 2
        offset += 5
    for index in range(q):
        let at = index * 4
        for field in range(4):
            queries[at + field] = input[offset + field]
        let left = queries[at]
        let down = queries[at + 1]
        let right = queries[at + 2]
        let up = queries[at + 3]
        if left < 0 or left >= right or right > 1_000_000 or down < 0 or down >= up or up > 1_000_000:
            return -1
        xs[nx] = left
        xs[nx + 1] = right
        ys[ny] = down
        ys[ny + 1] = up
        nx += 2
        ny += 2
        offset += 4

    nx = sras_sort_unique(xs.unsafe_ptr(), nx)
    ny = sras_sort_unique(ys.unsafe_ptr(), ny)
    var diff = InlineArray[Int64, MAX_COORDS * MAX_COORDS]()
    var prefix = InlineArray[Int64, STRIDE * STRIDE]()
    for index in range(n):
        let at = index * 5
        let x0 = sras_lower(xs.unsafe_ptr(), nx, updates[at])
        let x1 = sras_lower(xs.unsafe_ptr(), nx, updates[at + 2])
        let y0 = sras_lower(ys.unsafe_ptr(), ny, updates[at + 1])
        let y1 = sras_lower(ys.unsafe_ptr(), ny, updates[at + 3])
        let weight = updates[at + 4]
        diff[x0 * MAX_COORDS + y0] += weight
        diff[x1 * MAX_COORDS + y0] -= weight
        diff[x0 * MAX_COORDS + y1] -= weight
        diff[x1 * MAX_COORDS + y1] += weight

    for row in range(nx):
        for column in range(ny):
            let at = row * MAX_COORDS + column
            var value = diff[at]
            if row > 0:
                value += diff[(row - 1) * MAX_COORDS + column]
            if column > 0:
                value += diff[row * MAX_COORDS + column - 1]
            if row > 0 and column > 0:
                value -= diff[(row - 1) * MAX_COORDS + column - 1]
            diff[at] = value
    if nx > 1 and ny > 1:
        for row in range(nx - 1):
            for column in range(ny - 1):
                let value = diff[row * MAX_COORDS + column] % MODULUS
                let dx = (xs[row + 1] - xs[row]) % MODULUS
                let dy = (ys[column + 1] - ys[column]) % MODULUS
                let cell = value * ((dx * dy) % MODULUS) % MODULUS
                let at = (row + 1) * STRIDE + column + 1
                var sum = cell + prefix[row * STRIDE + column + 1] + prefix[(row + 1) * STRIDE + column] - prefix[row * STRIDE + column]
                sum %= MODULUS
                if sum < 0:
                    sum += MODULUS
                prefix[at] = sum

    var answers = InlineArray[Int64, MAX_Q]()
    for index in range(q):
        let at = index * 4
        let x0 = sras_lower(xs.unsafe_ptr(), nx, queries[at])
        let x1 = sras_lower(xs.unsafe_ptr(), nx, queries[at + 2])
        let y0 = sras_lower(ys.unsafe_ptr(), ny, queries[at + 1])
        let y1 = sras_lower(ys.unsafe_ptr(), ny, queries[at + 3])
        var value = prefix[x1 * STRIDE + y1] - prefix[x0 * STRIDE + y1] - prefix[x1 * STRIDE + y0] + prefix[x0 * STRIDE + y0]
        value %= MODULUS
        if value < 0:
            value += MODULUS
        answers[index] = value

    let required = 8 * q
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2
    for index in range(q):
        sras_store(output, 8 * index, answers[index])
    return Int64(required)
