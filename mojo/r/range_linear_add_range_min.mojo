from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_LENGTH = 64
comptime MAX_OPERATIONS = 64
comptime MAX_INPUT = 387
comptime BLOCK_WIDTH = 8
comptime MAX_BLOCKS = 8
comptime CHECKSUM_OFFSET = Int64(8_000_000)

fn range_linear_block_end(block: Int, n: Int) -> Int:
    return min((block + 1) * BLOCK_WIDTH, n)

fn range_linear_rebuild(data: UnsafePointer[Int64, MutAnyOrigin],
                        hull_x: UnsafePointer[Int64, MutAnyOrigin],
                        hull_y: UnsafePointer[Int64, MutAnyOrigin],
                        hull_count: UnsafePointer[Int64, MutAnyOrigin], block: Int, n: Int):
    let base = block * BLOCK_WIDTH
    var size = 0
    for x in range(base, range_linear_block_end(block, n)):
        while size >= 2:
            let p = base + size - 2
            let q = base + size - 1
            let cross = (hull_x[q] - hull_x[p]) * (data[x] - hull_y[p]) -
                (hull_y[q] - hull_y[p]) * (Int64(x) - hull_x[p])
            if cross > 0: break
            size -= 1
        hull_x[base + size] = Int64(x)
        hull_y[base + size] = data[x]
        size += 1
    hull_count[block] = Int64(size)

fn range_linear_push(data: UnsafePointer[Int64, MutAnyOrigin],
                     lazy_slope: UnsafePointer[Int64, MutAnyOrigin],
                     lazy_intercept: UnsafePointer[Int64, MutAnyOrigin], block: Int, n: Int):
    let start = block * BLOCK_WIDTH
    for i in range(start, range_linear_block_end(block, n)):
        data[i] += lazy_slope[block] * Int64(i) + lazy_intercept[block]
    lazy_slope[block] = 0
    lazy_intercept[block] = 0

fn range_linear_block_min(hull_x: UnsafePointer[Int64, MutAnyOrigin],
                          hull_y: UnsafePointer[Int64, MutAnyOrigin],
                          hull_count: UnsafePointer[Int64, MutAnyOrigin],
                          lazy_slope: UnsafePointer[Int64, MutAnyOrigin],
                          lazy_intercept: UnsafePointer[Int64, MutAnyOrigin], block: Int) -> Int64:
    let base = block * BLOCK_WIDTH
    var low = 0
    var high = Int(hull_count[block]) - 1
    while low < high:
        let middle = low + (high - low) / 2
        let left = hull_y[base + middle] + lazy_slope[block] * hull_x[base + middle]
        let right = hull_y[base + middle + 1] + lazy_slope[block] * hull_x[base + middle + 1]
        if left <= right: high = middle
        else: low = middle + 1
    return hull_y[base + low] + lazy_slope[block] * hull_x[base + low] + lazy_intercept[block]

@export("range_linear_add_range_min_benchmark")
fn range_linear_add_range_min_benchmark(input: UnsafePointer[Int64, ImmutAnyOrigin],
                                        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > MAX_INPUT: return -1
    if input[0] < 1 or input[0] > MAX_LENGTH or input[1] < 1 or input[1] > MAX_OPERATIONS: return -1
    let n = Int(input[0])
    let q = Int(input[1])
    if length < c_size_t(n + 2): return -1

    var data = InlineArray[Int64, MAX_LENGTH]()
    for i in range(n):
        if input[i + 2] < -1_000_000 or input[i + 2] > 1_000_000: return -1
        data[i] = input[i + 2]
    var hull_x = InlineArray[Int64, MAX_LENGTH]()
    var hull_y = InlineArray[Int64, MAX_LENGTH]()
    var hull_count = InlineArray[Int64, MAX_BLOCKS]()
    var lazy_slope = InlineArray[Int64, MAX_BLOCKS]()
    var lazy_intercept = InlineArray[Int64, MAX_BLOCKS]()
    for block in range((n + BLOCK_WIDTH - 1) / BLOCK_WIDTH):
        range_linear_rebuild(data.unsafe_ptr(), hull_x.unsafe_ptr(), hull_y.unsafe_ptr(),
                             hull_count.unsafe_ptr(), block, n)

    var cursor = n + 2
    var checksum = Int64(0)
    for operation in range(q):
        if c_size_t(cursor) >= length: return -1
        let opcode = input[cursor]
        cursor += 1
        if opcode == 0:
            if c_size_t(cursor + 4) > length: return -1
            let left = input[cursor]
            let right = input[cursor + 1]
            let slope = input[cursor + 2]
            let intercept = input[cursor + 3]
            cursor += 4
            if left < 0 or left >= right or right > Int64(n) or slope < -99 or slope > 99 or
                intercept < -100_000 or intercept > 100_000: return -1
            var position = Int(left)
            let stop_at = Int(right)
            while position < stop_at:
                let block = position / BLOCK_WIDTH
                let start = block * BLOCK_WIDTH
                let end = range_linear_block_end(block, n)
                if position == start and end <= stop_at:
                    lazy_slope[block] += slope
                    lazy_intercept[block] += intercept
                    position = end
                else:
                    range_linear_push(data.unsafe_ptr(), lazy_slope.unsafe_ptr(),
                                      lazy_intercept.unsafe_ptr(), block, n)
                    let end_position = min(end, stop_at)
                    for i in range(position, end_position): data[i] += slope * Int64(i) + intercept
                    range_linear_rebuild(data.unsafe_ptr(), hull_x.unsafe_ptr(), hull_y.unsafe_ptr(),
                                         hull_count.unsafe_ptr(), block, n)
                    position = end_position
        elif opcode == 1:
            if c_size_t(cursor + 2) > length: return -1
            let left = input[cursor]
            let right = input[cursor + 1]
            cursor += 2
            if left < 0 or left >= right or right > Int64(n): return -1
            var position = Int(left)
            let stop_at = Int(right)
            var minimum = Int64(0)
            var found = False
            while position < stop_at:
                let block = position / BLOCK_WIDTH
                let start = block * BLOCK_WIDTH
                let end = range_linear_block_end(block, n)
                if position == start and end <= stop_at:
                    let candidate = range_linear_block_min(hull_x.unsafe_ptr(), hull_y.unsafe_ptr(),
                        hull_count.unsafe_ptr(), lazy_slope.unsafe_ptr(), lazy_intercept.unsafe_ptr(), block)
                    if not found or candidate < minimum: minimum = candidate
                    found = True
                    position = end
                else:
                    let end_position = min(end, stop_at)
                    for i in range(position, end_position):
                        let candidate = data[i] + lazy_slope[block] * Int64(i) + lazy_intercept[block]
                        if not found or candidate < minimum: minimum = candidate
                        found = True
                    position = end_position
            checksum += Int64(operation + 1) * (minimum + CHECKSUM_OFFSET)
        else:
            return -1
    if c_size_t(cursor) == length: return checksum
    return -1
