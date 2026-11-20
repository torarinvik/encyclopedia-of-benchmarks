"""Independent models for bounded scalar benchmark contracts."""
import math
from decimal import Decimal, localcontext
from functools import lru_cache


def buzz_number(value):
    return int(value % 7 == 0 or (value >= 0 and str(value).endswith("7")))


def binomial_sequence(index):
    if not 0 <= index <= 230:
        return -1
    row = (math.isqrt(8 * index + 1) - 1) // 2
    return math.comb(row, index - row * (row + 1) // 2)


def binary_to_gray_code(value):
    if value < 0 or value > 2**63 - 1:
        return -1
    digits = format(value, "b")
    return int(digits[0] + "".join(str(int(a != b)) for a, b in zip(digits, digits[1:])), 2)


def bcd_conversion(value):
    return int(str(value), 16) if 0 <= value <= 9999 else -1


def triangular_number(value):
    return math.comb(value + 1, 2) if 0 <= value <= 4_294_967_295 else -1


def cake_numbers_sequence(value):
    if not 0 <= value <= 2_000_000:
        return -1
    return sum(math.comb(value, degree) for degree in range(min(value, 3) + 1))


def count_sorted_vowel_strings(value):
    return math.comb(value + 4, 4) if 0 <= value <= 30_000 else -1


def primorial_numbers_sequence(index):
    primes = (2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47)
    return math.prod(primes[:index]) if 0 <= index <= len(primes) else -1


def fibonacci_variant(index, algorithm):
    bounds = {"fibonacci_dp": 46, "fibonacci_recursive": 30, "fibonacci_formula": 35,
              "fibonacci_matrix": 92}
    if not 0 <= index <= bounds[algorithm]:
        return -1
    if algorithm == "fibonacci_formula":
        index += 1

    def pair(n):
        if n == 0:
            return 0, 1
        a, b = pair(n // 2)
        even, odd = a * (2*b - a), a*a + b*b
        return (odd, even + odd) if n % 2 else (even, odd)

    return pair(index)[0]


def fibonacci_number_check(value):
    if not -1_300_000_000 <= value <= 1_300_000_000:
        return -1
    target = abs(value)
    a, b = 0, 1
    while a < target:
        a, b = b, a + b
    return int(a == target)


def golombs_sequence(index):
    if not 0 <= index <= 64:
        return -1
    terms = [0, 1]
    for position in range(2, index + 2):
        terms.append(1 + terms[position - terms[terms[position - 1]]])
    return terms[index + 1]


def find_previous_power_of_two(value):
    if not 0 <= value <= 2_147_483_647:
        return -1
    return 0 if value == 0 else 1 << (value.bit_length() - 1)


def fermat_numbers_sequence(index):
    return (1 << (1 << index)) + 1 if 0 <= index <= 5 else -1


def figurate_number(value):
    if not 0 <= value <= 1_000_000:
        return -1

    def contains(dimension, minimum):
        low, high = minimum, value + 1
        while low < high:
            mid = (low + high) // 2
            term = math.comb(mid + dimension - 1, dimension) if mid else 0
            if term < value:
                low = mid + 1
            else:
                high = mid
        return (math.comb(low + dimension - 1, dimension) if low else 0) == value

    return sum((1 << (dimension-2)) for dimension in (2, 3, 4)
               if contains(dimension, 0 if dimension == 2 else 1))


def finding_number_of_digits_in_a_number(value):
    if value < 0 or value > 2**63 - 1:
        return -1
    return 0 if value == 0 else len(str(value))


def harshad_number(value):
    if not 1 <= value <= 2_147_483_647:
        return -1
    return int(value % sum(int(digit) for digit in str(value)) == 0)


def highest_set_bit(value):
    return value.bit_length() - 1 if 0 < value <= 2**63 - 1 else -1


def gray_to_binary(value):
    if not 0 <= value <= 2**63 - 1:
        return -1
    binary, bit = 0, 0
    for digit in format(value, "b"):
        bit ^= int(digit)
        binary = 2 * binary + bit
    return binary


def lowest_set_bit(value):
    if not 0 <= value <= 2_147_483_647:
        return -1
    if value == 0:
        return 0
    return 1 << ((value & -value).bit_length() - 1)


def index_of_right_most_set_bit(value):
    if not -(2**31) <= value < 2**31 or value == 0:
        return -1
    magnitude = abs(value)
    return (magnitude & -magnitude).bit_length() - 1


def is_square_free(value):
    if not 1 <= value <= 1_000_000:
        return -1
    return int(all(value % (factor*factor) != 0
                   for factor in range(2, math.isqrt(value) + 1)))


def jacobsthal_number(index):
    if not 0 <= index <= 64:
        return -1
    return ((1 << index) - (1 if index % 2 == 0 else -1)) // 3


def kolakoski_sequence(index):
    if not 0 <= index <= 63:
        return -1
    terms = [1, 2, 2]
    reader, symbol = 2, 1
    while len(terms) <= index:
        terms.extend([symbol] * terms[reader])
        reader += 1
        symbol = 3 - symbol
    return terms[index]


def kaprekar_number(value):
    if value < 1:
        return 0
    if value > 2_000_000_000:
        return -1
    if value == 1:
        return 1
    square = str(value * value)
    return int(any(int(square[cut:]) != 0 and int(square[:cut]) + int(square[cut:]) == value
                   for cut in range(1, len(square))))


def digit_factorial_predicate(value):
    if not -(2**31) <= value < 2**31:
        return -1
    if value <= 0:
        return 0
    return int(sum(math.factorial(int(digit)) for digit in str(value)) == value)


@lru_cache(maxsize=1)
def _partition_numbers():
    values = [1]
    for n in range(1, 301):
        total = 0
        k = 1
        while k * (3*k - 1) // 2 <= n:
            sign = 1 if k % 2 else -1
            total += sign * values[n - k * (3*k - 1) // 2]
            other = k * (3*k + 1) // 2
            if other <= n:
                total += sign * values[n - other]
            k += 1
        values.append(total)
    return values


def partition_variant(value, algorithm):
    minimum, maximum = (1, 300) if algorithm == "integer_partition" else (0, 100)
    return _partition_numbers()[value] if minimum <= value <= maximum else -(2**63)


def keith_number_checker(value):
    if not 2 <= value <= 1000:
        return -1
    if value < 10:
        return 1
    from simple_scalar_oracles import keith_number
    return keith_number(value)


def tetrahedral_sequence(index):
    return math.comb(index + 2, 3) if 0 <= index <= 3_810_777 else -1


def square_pyramidal_numbers(index):
    if not 0 <= index <= 2_097_151:
        return -1
    return math.comb(index + 1, 2) + 2 * math.comb(index + 1, 3)


@lru_cache(maxsize=1)
def _pi_reference():
    # Quadratic-convergence arithmetic-geometric mean, independent of BBP.
    with localcontext() as context:
        context.prec = 80
        a, b = Decimal(1), Decimal(1) / Decimal(2).sqrt()
        t, power = Decimal(1) / 4, Decimal(1)
        for _ in range(8):
            next_a = (a + b) / 2
            b = (a * b).sqrt()
            t -= power * (a - next_a) ** 2
            a = next_a
            power *= 2
        return +(a + b) ** 2 / (4 * t)


def bailey_borwein_plouffe(position):
    if not 1 <= position <= 10:
        return -1
    with localcontext() as context:
        context.prec = 70
        scaled = _pi_reference() * (Decimal(16) ** position)
        return int(scaled) % 16
