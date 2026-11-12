from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MODULUS = Int64(469_762_049)
comptime MAX_N = Int64(100_000_000)
comptime MAX_ROOT = 10_000
comptime MAX_TABLE = 20_000

fn floor_sqrt(value: Int64) -> Int64:
    var low: Int64 = 1
    var high: Int64 = 10_000
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

fn triangular_mod(value: Int64) -> Int64:
    var left = value
    var right = value + 1
    if (left & 1) == 0:
        left /= 2
    else:
        right /= 2
    return ((left % MODULUS) * (right % MODULUS)) % MODULUS

fn value_index(value: Int64, n: Int64, root: Int64, size: Int) -> Int:
    if value <= root:
        return size - Int(value)
    return Int(n / value)

@export("sum_of_multiplicative_function_large")
fn sum_of_multiplicative_function_large(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
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

    var quotients = InlineArray[Int64, MAX_TABLE]()
    var prime_count = InlineArray[Int64, MAX_TABLE]()
    var prime_sum = InlineArray[Int64, MAX_TABLE]()
    var prime_f = InlineArray[Int64, MAX_TABLE]()
    var values = InlineArray[Int64, MAX_TABLE]()
    var next_values = InlineArray[Int64, MAX_TABLE]()
    var composite = InlineArray[Bool, MAX_ROOT + 1]()
    var primes = InlineArray[Int64, MAX_ROOT + 1]()

    for index in range(1, high_count):
        quotients[index] = n / Int64(index)
    var value: Int64 = 1
    while value <= root:
        quotients[size - Int(value)] = value
        value += 1

    var prime_total = 0
    value = 2
    while value <= root:
        if composite[Int(value)]:
            value += 1
            continue
        primes[prime_total] = value
        prime_total += 1
        if value <= root / value:
            var multiple = value * value
            while multiple <= root:
                composite[Int(multiple)] = True
                multiple += value
        value += 1

    for index in range(1, size):
        prime_count[index] = quotients[index] - 1
        prime_sum[index] = normalize(triangular_mod(quotients[index]) - 1)
    var preceding_count: Int64 = 0
    var preceding_sum: Int64 = 0
    for p_index in range(prime_total):
        let prime = primes[p_index]
        let square = prime * prime
        var index = 1
        while index < size and quotients[index] >= square:
            let quotient_index = value_index(quotients[index] / prime, n, root, size)
            prime_count[index] -= prime_count[quotient_index] - preceding_count
            let sum_delta = normalize(prime_sum[quotient_index] - preceding_sum)
            prime_sum[index] = normalize(prime_sum[index] - (prime % MODULUS) * sum_delta)
            index += 1
        preceding_count += 1
        preceding_sum = normalize(preceding_sum + prime)

    for index in range(1, size):
        prime_f[index] = (a * (prime_count[index] % MODULUS) + b * prime_sum[index]) % MODULUS
        values[index] = prime_f[index]
        next_values[index] = prime_f[index]

    var position = prime_total
    while position > 0:
        position -= 1
        let prime = primes[position]
        var power = prime
        var exponent: Int64 = 1
        let prime_prefix = prime_f[value_index(prime, n, root, size)]
        while n / prime >= power:
            let local = (a * exponent + b * prime) % MODULUS
            let next_local = (a * (exponent + 1) + b * prime) % MODULUS
            let next_power = power * prime
            var index = 1
            while index < size and next_power <= quotients[index]:
                let quotient_index = value_index(quotients[index] / power, n, root, size)
                let non_prime_sum = normalize(values[quotient_index] - prime_prefix)
                next_values[index] = normalize(next_values[index] + local * non_prime_sum + next_local)
                index += 1
            power = next_power
            exponent += 1
        var copied = value_index(prime * prime, n, root, size) + 1
        if copied > size:
            copied = size
        for index in range(copied):
            values[index] = next_values[index]

    let answer_index = value_index(n, n, root, size)
    return normalize(values[answer_index] + 1)
