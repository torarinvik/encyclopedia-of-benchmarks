from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

const MAX_PARSEABLE_LENGTH: Int = 6
const MAX_DENOMINATIONS: Int64 = 4
const MAX_DENOMINATION: Int64 = 16
const DISTANCE_INF: Int = 1_000_000

fn fna_gcd(left_value: Int64, right_value: Int64) -> Int64:
    var left = left_value
    var right = right_value
    while right != 0:
        let remainder = left % right
        left = right
        right = remainder
    return left

fn fna_apery(input: UnsafePointer[Int64, ImmutAnyOrigin], count: Int,
             modulus: Int) -> Int64:
    var distance = List[Int](length=16, fill=DISTANCE_INF)
    var settled = List[Bool](length=16, fill=False)
    distance[0] = 0
    for _ in range(modulus):
        var source = -1
        var best = DISTANCE_INF
        for residue in range(modulus):
            if not settled[residue] and distance[residue] < best:
                source = residue
                best = distance[residue]
        if source < 0:
            return -1
        settled[source] = True
        for index in range(count):
            let coin = Int(input[index + 1])
            let target = (source + coin) % modulus
            let candidate = best + coin
            if candidate < distance[target]:
                distance[target] = candidate
    var maximum = 0
    for residue in range(modulus):
        if distance[residue] > maximum:
            maximum = distance[residue]
    return Int64(maximum - modulus)

fn fna_solve(input: UnsafePointer[Int64, ImmutAnyOrigin], length: Int) -> Int64:
    if length < 1 or length > MAX_PARSEABLE_LENGTH:
        return -1
    let count_value = input[0]
    if count_value < 2 or count_value > MAX_DENOMINATIONS or length != Int(count_value + 1):
        return -1
    let count = Int(count_value)
    var common: Int64 = 0
    var minimum = MAX_DENOMINATION + 1
    for index in range(count):
        let coin = input[index + 1]
        if coin < 2 or coin > MAX_DENOMINATION:
            return -1
        for previous in range(index):
            if coin == input[previous + 1]:
                return -1
        common = fna_gcd(common, coin)
        if Int(coin) < minimum:
            minimum = Int(coin)
    if common != 1:
        return -1
    return fna_apery(input + 1, count, minimum)

@export("frobenius_number_apery")
fn frobenius_number_apery(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_PARSEABLE_LENGTH:
        return -1
    return fna_solve(input, Int(length))
