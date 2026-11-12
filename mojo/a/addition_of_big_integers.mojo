from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List


@export("addition_of_big_integers")
fn addition_of_big_integers(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 68:
        return -1
    let raw_a = input[0]
    let raw_b = input[1]
    if raw_a < 1 or raw_a > 33 or raw_b < 1 or raw_b > 33:
        return -1
    let len_a = Int(raw_a)
    let len_b = Int(raw_b)
    if length != c_size_t(2 + len_a + len_b):
        return -1

    var starts = List[Int]()
    var counts = List[Int]()
    var negatives = List[Bool]()
    starts.append(2)
    starts.append(2 + len_a)
    for operand in range(2):
        var text_length = len_b
        if operand == 0: text_length = len_a
        if text_length < 1 or text_length > 33: return -1
        let sign_at = starts[operand]
        let negative = input[sign_at] == 45
        var sign_length = 0
        if negative: sign_length = 1
        let digit_start = sign_at + sign_length
        let digit_count = text_length - sign_length
        if digit_count < 1 or digit_count > 32: return -1
        for index in range(digit_count):
            let byte = input[digit_start + index]
            if byte < 48 or byte > 57: return -1
            if index == 0 and digit_count > 1 and byte == 48: return -1
        if negative and digit_count == 1 and input[digit_start] == 48: return -1
        starts[operand] = digit_start
        counts.append(digit_count)
        negatives.append(negative)

    var reversed = List[Int](capacity=33)
    for _ in range(33): reversed.append(0)
    var digits = 0
    var negative_result = False
    if negatives[0] == negatives[1]:
        negative_result = negatives[0]
        let width = max(counts[0], counts[1])
        var carry = 0
        for offset in range(width):
            var da = 0
            var db = 0
            if offset < counts[0]: da = Int(input[starts[0] + counts[0] - 1 - offset] - 48)
            if offset < counts[1]: db = Int(input[starts[1] + counts[1] - 1 - offset] - 48)
            let total = da + db + carry
            reversed[digits] = Int(total % 10)
            digits += 1
            carry = Int(total // 10)
        if carry != 0:
            reversed[digits] = carry
            digits += 1
    else:
        var order = 0
        if counts[0] > counts[1]:
            order = 1
        elif counts[0] < counts[1]:
            order = -1
        else:
            for index in range(counts[0]):
                if order == 0:
                    let da = input[starts[0] + index]
                    let db = input[starts[1] + index]
                    if da > db: order = 1
                    elif da < db: order = -1
        if order == 0:
            reversed[0] = 0
            digits = 1
        else:
            var big = 0
            if order < 0: big = 1
            let small = 1 - big
            negative_result = negatives[big]
            var borrow = 0
            for offset in range(counts[big]):
                let da = Int(input[starts[big] + counts[big] - 1 - offset] - 48)
                var db = 0
                if offset < counts[small]: db = Int(input[starts[small] + counts[small] - 1 - offset] - 48)
                let digit = da - db - borrow
                borrow = 0
                var normalized = digit
                if digit < 0:
                    borrow = 1
                    normalized += 10
                reversed[digits] = Int(normalized)
                digits += 1
            while digits > 1 and reversed[digits - 1] == 0:
                digits -= 1

    var sign_length = 0
    if negative_result: sign_length = 1
    let output_length = digits + sign_length
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_length):
        return -2
    var encoded = List[UInt8](capacity=output_length)
    if negative_result: encoded.append(UInt8(45))
    for index in range(digits):
        encoded.append(UInt8(48 + reversed[digits - 1 - index]))
    for index in range(output_length): output[index] = encoded[index]
    return Int64(output_length)
