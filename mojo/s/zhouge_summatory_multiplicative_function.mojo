from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MODULUS = Int64(469_762_049)
comptime MAX_N = Int64(10_000_000)
comptime MAX_ROOT = 3162
comptime MAX_TABLE = 6324

fn floor_sqrt(value: Int64) -> Int64:
    var low: Int64 = 1
    var high: Int64 = MAX_ROOT
    while low < high:
        let middle = low + (high - low + 1) / 2
        if middle <= value / middle:
            low = middle
        else:
            high = middle - 1
    return low

fn normalize(value: Int64) -> Int64:
    var remainder = value % MODULUS
    if remainder < 0:
        remainder += MODULUS
    return remainder

fn quotient_at(index: Int, n: Int64, high_count: Int, size: Int) -> Int64:
    if index < high_count:
        return n / Int64(index)
    return Int64(size - index)

fn value_index(value: Int64, n: Int64, root: Int64, size: Int) -> Int:
    if value <= root:
        return size - Int(value)
    return Int(n / value)

fn upper_bound(inout primes: InlineArray[Int64, MAX_ROOT + 1], count: Int, value: Int64) -> Int:
    var low = 0
    var high = count
    while low < high:
        let middle = low + (high - low) / 2
        if primes[middle] <= value:
            low = middle + 1
        else:
            high = middle
    return low

fn apply_skipped_prime_range(index: Int, stage: Int,
    inout small_lo: InlineArray[Int32, MAX_TABLE],
    inout small_hi: InlineArray[Int32, MAX_TABLE],
    inout simple_cursor: InlineArray[Int32, MAX_TABLE],
    inout prefix_g: InlineArray[Int64, MAX_ROOT + 1],
    inout smooth_sum: InlineArray[Int64, MAX_TABLE]):
    var next = Int32(stage + 1)
    if next < small_lo[index]:
        next = small_lo[index]
    if next > small_hi[index]:
        next = small_hi[index]
    let old = simple_cursor[index]
    if next < old:
        smooth_sum[index] = normalize(smooth_sum[index] + prefix_g[Int(old)] - prefix_g[Int(next)])
        simple_cursor[index] = next

fn apply_skipped_power_sums(index: Int, stage: Int,
    inout small_lo: InlineArray[Int32, MAX_TABLE],
    inout small_hi: InlineArray[Int32, MAX_TABLE],
    inout g_cursor: InlineArray[Int32, MAX_TABLE],
    inout prefix_sum: InlineArray[Int64, MAX_ROOT + 1],
    inout g_zero: InlineArray[Int64, MAX_TABLE],
    inout g_one: InlineArray[Int64, MAX_TABLE]):
    var next = Int32(stage)
    if next < small_lo[index]:
        next = small_lo[index]
    if next > small_hi[index]:
        next = small_hi[index]
    let old = g_cursor[index]
    if next > old:
        g_zero[index] = normalize(g_zero[index] - Int64(next - old))
        g_one[index] = normalize(g_one[index] - (prefix_sum[Int(next)] - prefix_sum[Int(old)]))
        g_cursor[index] = next

fn small_value(value_input: Int64,
    inout smallest: InlineArray[Int32, MAX_ROOT + 1], a: Int64, b: Int64) -> Int64:
    var value = value_input
    var result: Int64 = 1
    while value > 1:
        let prime = Int64(smallest[Int(value)])
        var exponent: Int64 = 0
        while value % prime == 0:
            value /= prime
            exponent += 1
        result = result * ((a * exponent + b * prime) % MODULUS) % MODULUS
    return result

@export("zhouge_summatory_multiplicative_function")
fn zhouge_summatory_multiplicative_function(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3:
        return -1
    let n = input[0]
    let a = input[1]
    let b = input[2]
    if n < 1 or n > MAX_N or a < 0 or a >= MODULUS or b < 0 or b >= MODULUS:
        return -1

    let root = floor_sqrt(n)
    var high_count = Int(n / root)
    while high_count > 1 and n / Int64(high_count - 1) == root:
        high_count -= 1
    let size = high_count + Int(root)

    var smallest = InlineArray[Int32, MAX_ROOT + 1](fill=0)
    var primes = InlineArray[Int64, MAX_ROOT + 1](fill=0)
    var prefix_sum = InlineArray[Int64, MAX_ROOT + 1](fill=0)
    var prefix_g = InlineArray[Int64, MAX_ROOT + 1](fill=0)
    var g_zero = InlineArray[Int64, MAX_TABLE](fill=0)
    var g_one = InlineArray[Int64, MAX_TABLE](fill=0)
    var smooth_sum = InlineArray[Int64, MAX_TABLE](fill=1)
    var small_lo = InlineArray[Int32, MAX_TABLE](fill=0)
    var small_hi = InlineArray[Int32, MAX_TABLE](fill=0)
    var simple_cursor = InlineArray[Int32, MAX_TABLE](fill=0)
    var g_cursor = InlineArray[Int32, MAX_TABLE](fill=0)

    var prime_total = 0
    var value: Int64 = 2
    while value <= root:
        if smallest[Int(value)] != 0:
            value += 1
            continue
        smallest[Int(value)] = Int32(value)
        primes[prime_total] = value
        prime_total += 1
        if value <= root / value:
            var multiple = value * value
            while multiple <= root:
                if smallest[Int(multiple)] == 0:
                    smallest[Int(multiple)] = Int32(value)
                multiple += value
        value += 1

    for p_index in range(prime_total):
        let prime = primes[p_index]
        prefix_sum[p_index + 1] = normalize(prefix_sum[p_index] + prime)
        prefix_g[p_index + 1] = normalize(prefix_g[p_index] + a + b * prime)

    for index in range(1, size):
        let y = quotient_at(index, n, high_count, size)
        small_lo[index] = Int32(upper_bound(primes, prime_total, floor_sqrt(y)))
        small_hi[index] = Int32(upper_bound(primes, prime_total, y))
        simple_cursor[index] = small_hi[index]
        g_cursor[index] = small_lo[index]
        g_zero[index] = y % MODULUS
        var left = y
        var right = y + 1
        if (left & 1) == 0:
            left /= 2
        else:
            right /= 2
        g_one[index] = ((left % MODULUS) * (right % MODULUS)) % MODULUS

    for stage in range(prime_total):
        let prime = primes[stage]
        let square = prime * prime
        for index in range(1, size):
            let y = quotient_at(index, n, high_count, size)
            if y < square:
                break
            let child = value_index(y / prime, n, root, size)
            apply_skipped_power_sums(child, stage, small_lo, small_hi, g_cursor,
                                     prefix_sum, g_zero, g_one)
            g_zero[index] = normalize(g_zero[index] - g_zero[child])
            g_one[index] = normalize(g_one[index] - prime * g_one[child])
    for index in range(1, size):
        apply_skipped_power_sums(index, prime_total, small_lo, small_hi, g_cursor,
                                 prefix_sum, g_zero, g_one)

    var stage = prime_total
    while stage > 0:
        stage -= 1
        let prime = primes[stage]
        let square = prime * prime
        for index in range(1, size):
            let y = quotient_at(index, n, high_count, size)
            if y < square:
                break
            apply_skipped_prime_range(index, stage, small_lo, small_hi, simple_cursor, prefix_g, smooth_sum)
            var power = prime
            var exponent: Int64 = 1
            while power <= y:
                let child = value_index(y / power, n, root, size)
                apply_skipped_prime_range(child, stage, small_lo, small_hi, simple_cursor, prefix_g, smooth_sum)
                let local = (a * exponent + b * prime) % MODULUS
                smooth_sum[index] = normalize(smooth_sum[index] + local * smooth_sum[child])
                power *= prime
                exponent += 1

    var answer = smooth_sum[1]
    for value in range(1, Int(root) + 1):
        let child = value_index(n / Int64(value), n, root, size)
        let large_prime_sum = normalize(a * normalize(g_zero[child] - 1) + b * normalize(g_one[child] - 1))
        answer = normalize(answer + small_value(Int64(value), smallest, a, b) * large_prime_sum)
    return answer
