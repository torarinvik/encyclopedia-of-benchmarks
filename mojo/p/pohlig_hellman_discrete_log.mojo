from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

const MIN_P: Int64 = 3
const MAX_P: Int64 = 1009
const MAX_PARSEABLE_LENGTH = 4

fn is_prime(value: Int64) -> Bool:
    if value < 2:
        return False
    var divisor: Int64 = 2
    while divisor * divisor <= value:
        if value % divisor == 0:
            return False
        if divisor == 2:
            divisor = 3
        else:
            divisor += 2
    return True

fn pow_mod(base_value: Int64, exponent_value: Int64, modulus: Int64) -> Int64:
    var result: Int64 = 1
    var factor = base_value % modulus
    var exponent = exponent_value
    while exponent > 0:
        if (exponent & 1) != 0:
            result = result * factor % modulus
        factor = factor * factor % modulus
        exponent >>= 1
    return result

fn factorize(value_value: Int64, primes: List[Int64], exponents: List[Int64]) -> Int:
    var value = value_value
    var count = 0
    var divisor: Int64 = 2
    while divisor * divisor <= value:
        if value % divisor != 0:
            if divisor == 2:
                divisor = 3
            else:
                divisor += 2
            continue
        var exponent: Int64 = 0
        while value % divisor == 0:
            value = value // divisor
            exponent += 1
        primes[count] = divisor
        exponents[count] = exponent
        count += 1
        if divisor == 2:
            divisor = 3
        else:
            divisor += 2
    if value > 1:
        primes[count] = value
        exponents[count] = 1
        count += 1
    return count

fn prime_order_log(generator: Int64, target: Int64, order: Int64,
                   modulus: Int64) -> Int64:
    var step: Int64 = 1
    while step * step < order:
        step += 1
    var baby = List[Int64](capacity=64)
    for _ in range(64):
        baby.append(0)
    var value: Int64 = 1
    for j in range(Int(step)):
        baby[j] = value
        value = value * generator % modulus
    let giant_factor = pow_mod(pow_mod(generator, step, modulus), modulus - 2, modulus)
    var probe = target
    for i in range(Int(step) + 1):
        for j in range(Int(step)):
            if baby[j] == probe:
                let candidate = Int64(i) * step + Int64(j)
                if candidate < order:
                    return candidate
        probe = probe * giant_factor % modulus
    return -1

fn inverse_mod(value: Int64, modulus: Int64) -> Int64:
    var old_r = value
    var r = modulus
    var old_s: Int64 = 1
    var s: Int64 = 0
    while r != 0:
        let quotient = old_r // r
        let next_r = old_r - quotient * r
        let next_s = old_s - quotient * s
        old_r = r
        r = next_r
        old_s = s
        s = next_s
    if old_r != 1:
        return -1
    return (old_s % modulus + modulus) % modulus

fn pohlig_hellman(p: Int64, base: Int64, target: Int64) -> Int64:
    if target == 0:
        return -2
    var primes = List[Int64](capacity=16)
    var exponents = List[Int64](capacity=16)
    for _ in range(16):
        primes.append(0)
        exponents.append(0)
    let factor_count = factorize(p - 1, primes, exponents)
    var order = p - 1
    for i in range(factor_count):
        let prime = primes[i]
        while order % prime == 0 and pow_mod(base, order // prime, p) == 1:
            order = order // prime
    if order == 1:
        if target == 1:
            return 0
        return -2

    var order_primes = List[Int64](capacity=16)
    var order_exponents = List[Int64](capacity=16)
    for _ in range(16):
        order_primes.append(0)
        order_exponents.append(0)
    let order_factor_count = factorize(order, order_primes, order_exponents)
    var solution: Int64 = 0
    var combined_modulus: Int64 = 1
    for i in range(order_factor_count):
        let prime = order_primes[i]
        let exponent = order_exponents[i]
        var component_modulus: Int64 = 1
        var j: Int64 = 0
        while j < exponent:
            component_modulus *= prime
            j += 1
        var partial_log: Int64 = 0
        var place: Int64 = 1
        let prime_generator = pow_mod(base, order // prime, p)
        var digit_index: Int64 = 0
        while digit_index < exponent:
            let current_power = pow_mod(base, partial_log, p)
            let inverse_current = pow_mod(current_power, p - 2, p)
            let residual = target * inverse_current % p
            let digit_target = pow_mod(residual, order // (place * prime), p)
            let digit = prime_order_log(prime_generator, digit_target, prime, p)
            if digit < 0:
                return -2
            partial_log += digit * place
            place *= prime
            digit_index += 1
        if combined_modulus == 1:
            solution = partial_log
            combined_modulus = component_modulus
        else:
            let inverse = inverse_mod(combined_modulus % component_modulus, component_modulus)
            if inverse < 0:
                return -2
            let difference = (partial_log - solution) % component_modulus
            let adjustment = ((difference + component_modulus) % component_modulus) * inverse % component_modulus
            solution += combined_modulus * adjustment
            combined_modulus *= component_modulus
    solution %= order
    if pow_mod(base, solution, p) == target:
        return solution
    return -2

fn verify(input: UnsafePointer[Int64, ImmutAnyOrigin], length: Int) -> Int64:
    if length != 3:
        return -1
    let p = input[0]
    let base = input[1]
    let target = input[2]
    if p < MIN_P or p > MAX_P or not is_prime(p) or base < 1 or base >= p or target < 0 or target >= p:
        return -1
    return pohlig_hellman(p, base, target)

@export("pohlig_hellman_discrete_log")
fn pohlig_hellman_discrete_log(input: UnsafePointer[Int64, ImmutAnyOrigin],
                               length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1
        or length > MAX_PARSEABLE_LENGTH or length != 3:
        return -1
    return verify(input, Int(length))
