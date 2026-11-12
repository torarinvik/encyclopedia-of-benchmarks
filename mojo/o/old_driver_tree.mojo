from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime ODT_MAX_N = 32
comptime ODT_MAX_Q = 32
comptime ODT_MAX_INPUT = 195
comptime ODT_MAX_RUNS = 36

fn odt_lower_bound(runs: InlineArray[Int64, 3 * ODT_MAX_RUNS], count: Int, point: Int64) -> Int:
    var lo = 0
    var hi = count
    while lo < hi:
        let mid = lo + (hi - lo) // 2
        if runs[3 * mid] < point: lo = mid + 1
        else: hi = mid
    return lo

fn odt_split_at(inout runs: InlineArray[Int64, 3 * ODT_MAX_RUNS], inout count: Int, point: Int64, n: Int64):
    if point <= 0 or point >= n: return
    let at = odt_lower_bound(runs, count, point)
    if at < count and runs[3 * at] == point: return
    let old_right = runs[3 * (at - 1) + 1]
    let old_value = runs[3 * (at - 1) + 2]
    var i = count
    while i > at:
        runs[3 * i] = runs[3 * (i - 1)]
        runs[3 * i + 1] = runs[3 * (i - 1) + 1]
        runs[3 * i + 2] = runs[3 * (i - 1) + 2]
        i -= 1
    runs[3 * (at - 1) + 1] = point - 1
    runs[3 * at] = point
    runs[3 * at + 1] = old_right
    runs[3 * at + 2] = old_value
    count += 1

fn odt_coalesce(inout runs: InlineArray[Int64, 3 * ODT_MAX_RUNS], inout count: Int):
    var write = 0
    for read in range(count):
        if write > 0 and runs[3 * (write - 1) + 1] + 1 == runs[3 * read] and runs[3 * (write - 1) + 2] == runs[3 * read + 2]:
            runs[3 * (write - 1) + 1] = runs[3 * read + 1]
        else:
            for field in range(3): runs[3 * write + field] = runs[3 * read + field]
            write += 1
    count = write

fn odt_modular_power(base: Int64, exponent_input: Int64, modulus: Int64) -> Int64:
    var exponent = exponent_input
    var value = base % modulus
    if value < 0: value += modulus
    var result = 1 % modulus
    while exponent > 0:
        if (exponent & 1) != 0: result = result * value % modulus
        value = value * value % modulus
        exponent >>= 1
    return result

fn odt_store_le(value: Int64, output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int):
    let bits = bitcast[UInt64](value)
    for byte in range(8): output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("old_driver_tree")
fn old_driver_tree(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                   output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > ODT_MAX_INPUT: return -1
    let nv = input[0]
    let qv = input[1]
    if nv < 1 or nv > ODT_MAX_N or qv < 0 or qv > ODT_MAX_Q or Int(length) < 2 + Int(nv): return -1
    let n = Int(nv)
    let q = Int(qv)
    var initial = InlineArray[Int64, ODT_MAX_N]()
    var ops = InlineArray[Int64, 5 * ODT_MAX_Q]()
    var cursor = 2 + n
    var answer_count = 0
    for i in range(n):
        initial[i] = input[2 + i]
        if initial[i] < -1000 or initial[i] > 1000: return -1
    for i in range(q):
        if cursor >= Int(length): return -1
        let kind = input[cursor]
        cursor += 1
        let words = 4 if kind == 3 else 3 if kind >= 0 and kind <= 2 else 0
        if words == 0 or Int(length) - cursor < words: return -1
        let left = input[cursor]
        let right = input[cursor + 1]
        let arg = input[cursor + 2]
        var extra: Int64 = 0
        cursor += 3
        if kind == 3: extra = input[cursor]; cursor += 1
        if left < 0 or left > right or right >= nv: return -1
        if (kind <= 1 and (arg < -1000 or arg > 1000)) or (kind == 2 and (arg < 1 or arg > right - left + 1)) or (kind == 3 and (arg < 0 or arg > 8 or extra < 1 or extra > 1_000_000_000)): return -1
        let base = 5 * i
        ops[base] = kind
        ops[base + 1] = left
        ops[base + 2] = right
        ops[base + 3] = arg
        ops[base + 4] = extra
        if kind >= 2: answer_count += 1
    if cursor != Int(length) or Int(length) > 2 + ODT_MAX_N + 5 * ODT_MAX_Q: return -1
    let required = 8 * answer_count
    if required > 0 and (output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < required): return -2
    var runs = InlineArray[Int64, 3 * ODT_MAX_RUNS]()
    var run_count = 0
    for i in range(n):
        if run_count > 0 and runs[3 * (run_count - 1) + 2] == initial[i]: runs[3 * (run_count - 1) + 1] = Int64(i)
        else:
            runs[3 * run_count] = Int64(i)
            runs[3 * run_count + 1] = Int64(i)
            runs[3 * run_count + 2] = initial[i]
            run_count += 1
    var written = 0
    for oi in range(q):
        let base = 5 * oi
        let kind = ops[base]
        let left = ops[base + 1]
        let right = ops[base + 2]
        let arg = ops[base + 3]
        let extra = ops[base + 4]
        if kind <= 1:
            odt_split_at(runs, run_count, right + 1, nv)
            odt_split_at(runs, run_count, left, nv)
            let start = odt_lower_bound(runs, run_count, left)
            let finish = odt_lower_bound(runs, run_count, right + 1)
            if kind == 0:
                let removed = finish - start
                let old_count = run_count
                for i in range(finish, old_count):
                    runs[3 * (i - removed)] = runs[3 * i]
                    runs[3 * (i - removed) + 1] = runs[3 * i + 1]
                    runs[3 * (i - removed) + 2] = runs[3 * i + 2]
                run_count = old_count - removed
                var i = run_count
                while i > start:
                    runs[3 * i] = runs[3 * (i - 1)]
                    runs[3 * i + 1] = runs[3 * (i - 1) + 1]
                    runs[3 * i + 2] = runs[3 * (i - 1) + 2]
                    i -= 1
                runs[3 * start] = left
                runs[3 * start + 1] = right
                runs[3 * start + 2] = arg
                run_count += 1
            else:
                for i in range(start, finish): runs[3 * i + 2] += arg
            odt_coalesce(runs, run_count)
        elif kind == 2:
            var ordered = InlineArray[Int64, ODT_MAX_N]()
            var used = 0
            for i in range(run_count):
                let lo = max(runs[3 * i], left)
                let hi = min(runs[3 * i + 1], right)
                if lo <= hi:
                    for _ in range(Int(hi - lo + 1)):
                        var at = used
                        while at > 0 and ordered[at - 1] > runs[3 * i + 2]: ordered[at] = ordered[at - 1]; at -= 1
                        ordered[at] = runs[3 * i + 2]
                        used += 1
            odt_store_le(ordered[Int(arg - 1)], output, 8 * written)
            written += 1
        else:
            var total: Int64 = 0
            for i in range(run_count):
                let lo = max(runs[3 * i], left)
                let hi = min(runs[3 * i + 1], right)
                if lo <= hi: total = (total + (hi - lo + 1) * odt_modular_power(runs[3 * i + 2], arg, extra)) % extra
            odt_store_le(total, output, 8 * written)
            written += 1
    return Int64(required)
