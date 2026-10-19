from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn area_isqrt(value: Int64) -> Int64:
    var low: Int64 = 0
    var high: Int64 = 3037000499
    var answer: Int64 = 0
    while low <= high:
        let middle = low + (high - low) / 2
        if middle == 0 or middle <= value / middle:
            answer = middle
            low = middle + 1
        else:
            high = middle - 1
    return answer

fn area_scale_pi(value: Int64) -> Int64:
    return value * 3 + value * 141592654 / 1000000000

fn area_scale_pi_squared(value: Int64) -> Int64:
    return value * 9 + value * 869604401 / 1000000000

fn area_polygon_coefficient(sides: Int64) -> Int64:
    if sides == 3: return 433012701
    if sides == 4: return 1000000000
    if sides == 5: return 1720477400
    if sides == 6: return 2598076211
    if sides == 7: return 3633912444
    if sides == 8: return 4828427124
    if sides == 9: return 6181824193
    if sides == 10: return 7694208842
    if sides == 11: return 9365639906
    if sides == 12: return 11196152422
    if sides == 13: return 13185768328
    if sides == 14: return 15334501936
    if sides == 15: return 17642362910
    if sides == 16: return 20109357968
    if sides == 17: return 22735491898
    if sides == 18: return 25520768188
    if sides == 19: return 28465189427
    if sides == 20: return 31568757573
    if sides == 21: return 34831474123
    if sides == 22: return 38253340244
    if sides == 23: return 41834356852
    if sides == 24: return 45574524676
    if sides == 25: return 49473844301
    if sides == 26: return 53532316204
    if sides == 27: return 57749940771
    if sides == 28: return 62126718324
    if sides == 29: return 66662649129
    if sides == 30: return 71357733406
    if sides == 31: return 76211971344
    if sides == 32: return 81225363100
    return -1

fn area_milli(operation: Int64, a: Int64, b: Int64, c: Int64) -> Int64:
    if operation == 0: return a * a * 1000
    if operation == 1: return a * b * 1000
    if operation == 2: return a * b * 500
    if operation == 3: return area_scale_pi(a * a * 1000)
    if operation == 4: return a * b * 1000
    if operation == 5: return (a + b) * c * 500
    if operation == 6:
        let perimeter = a + b + c
        if a + b < c or a + c < b or b + c < a: return -1
        let radicand = perimeter * (perimeter - 2 * a) * (perimeter - 2 * b) * (perimeter - 2 * c)
        return area_isqrt(radicand * 1000000) / 4
    if operation == 7: return area_scale_pi(a * b * 1000)
    if operation == 8: return a * b * 500
    if operation == 9: return 6 * a * a * 1000
    if operation == 10: return 2 * (a * b + a * c + b * c) * 1000
    if operation == 11: return area_scale_pi(4 * a * a * 1000)
    if operation == 12: return area_scale_pi(3 * a * a * 1000)
    if operation == 13: return area_scale_pi(2 * a * (b + a) * 1000)
    if operation == 14: return area_scale_pi(2 * a * b * 1000)
    if operation == 15:
        let slant_milli = area_isqrt((a * a + b * b) * 1000000)
        return area_scale_pi(a * a * 1000 + a * slant_milli)
    if operation == 16:
        let slant_milli = area_isqrt((a * a + b * b) * 1000000)
        return area_scale_pi(a * slant_milli)
    if operation == 17: return (a * a + 2 * a * b) * 1000
    if operation == 18:
        var difference = a - b
        if difference < 0: difference = -difference
        let slant_milli = area_isqrt((c * c + difference * difference) * 1000000)
        return area_scale_pi((a * a + b * b) * 1000 + (a + b) * slant_milli)
    if operation == 19: return area_scale_pi_squared(4 * a * b * 1000)
    if operation == 20:
        let coefficient = area_polygon_coefficient(a)
        if coefficient < 0: return -1
        return coefficient * b * b / 1000000
    if operation == 21:
        let coefficient = area_polygon_coefficient(a)
        if coefficient < 0: return -1
        let base_area = coefficient * b * b / 1000000
        return 2 * base_area + a * b * c * 1000
    return -1

@export("area_benchmark")
fn area_benchmark(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 1025:
        return -1
    let count = values[0]
    if count < 0 or count > 256 or length != c_size_t(1 + 4 * count):
        return -1
    var checksum: Int64 = 0
    for index in range(Int(count)):
        let position = 1 + 4 * index
        let op = values[position]
        let a = values[position + 1]
        let b = values[position + 2]
        let c = values[position + 3]
        if op < 0 or op > 21 or a < 0 or a > 1000 or b < 0 or b > 1000 or c < 0 or c > 1000:
            return -1
        if (op == 0 or op == 3 or op == 9 or op == 11 or op == 12) and (b != 0 or c != 0):
            return -1
        if (op == 1 or op == 2 or op == 4 or op == 7 or op == 8 or (op >= 13 and op <= 17) or op == 19 or op == 20) and c != 0:
            return -1
        let result = area_milli(op, a, b, c)
        if result < 0:
            return -1
        checksum += Int64(index + 1) * (result + 1000000007)
    return checksum
