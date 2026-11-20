from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn spatial_choose(total: Int64, selected0: Int64) -> Int64:
    if total < 0 or selected0 < 0 or selected0 > total: return 0
    var selected = selected0
    if total - selected < selected: selected = total - selected
    var value = Int64(1)
    for factor in range(1, Int(selected) + 1):
        value = value * (total - selected + Int64(factor)) // Int64(factor)
    return value

fn spatial_multinomial3(total: Int64, first: Int64, second: Int64) -> Int64:
    if total < 0 or first < 0 or second < 0 or first > total or second > total or
        first + second > total: return 0
    return spatial_choose(total, first) * spatial_choose(total - first, second)

fn spatial_gcd(mut left: Int64, mut right: Int64) -> Int64:
    while right != 0:
        let remainder = left % right
        left = right
        right = remainder
    return left

@export("spatial_motif_different_type_contact_pmf")
fn spatial_motif_different_type_contact_pmf(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin],
        capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 5: return -1
    let n = input[0]
    let x1 = input[1]
    let y1 = input[2]
    let x2 = input[3]
    let y2 = input[4]
    if n < 1 or n > 10 or x1 < 0 or y1 < 0 or x2 < 0 or y2 < 0 or
        x1 > n or y1 > n or x2 > n or y2 > n:
        return -1
    if x1 + y1 > n or x2 + y2 > n:
        return -1

    let denominator = spatial_multinomial3(n, x2, y2)
    var numerators = List[Int64]()
    for _ in range(Int(n) + 1): numerators.append(0)
    let neither1 = n - x1 - y1
    for contacts in range(Int(n) + 1):
        for xx in range(Int(x1) + 1):
            for xy in range(Int(x1) - xx + 1):
                let yx = contacts - xy
                if yx < 0 or yx > Int(y1): continue
                for yy in range(Int(y1) - yx + 1):
                    let ways = spatial_multinomial3(x1, Int64(xx), Int64(xy)) *
                        spatial_multinomial3(y1, Int64(yx), Int64(yy)) *
                        spatial_multinomial3(neither1, x2 - Int64(xx) - Int64(yx),
                                             y2 - Int64(xy) - Int64(yy))
                    numerators[contacts] = numerators[contacts] + ways

    var expected_numerator = Int64(0)
    for contacts in range(Int(n) + 1):
        expected_numerator = expected_numerator + Int64(contacts) * numerators[contacts]
    var expected_denominator = denominator
    let divisor = spatial_gcd(expected_numerator, expected_denominator)
    expected_numerator = expected_numerator // divisor
    expected_denominator = expected_denominator // divisor
    let bytes = (Int(n) + 5) * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    let words = List[Int64]()
    words.append(n)
    words.append(denominator)
    for contacts in range(Int(n) + 1): words.append(numerators[contacts])
    words.append(expected_numerator)
    words.append(expected_denominator)
    for word in range(len(words)):
        let bits = UInt64(words[word])
        for byte in range(8): output[8 * word + byte] = UInt8((bits >> (8 * byte)) & 255)
    return Int64(bytes)
