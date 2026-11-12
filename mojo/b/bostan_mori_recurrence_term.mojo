from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias MAX_ORDER = 8
alias MODULUS = 998244353

fn bmr_convolve(left: InlineArray[Int64, MAX_ORDER + 1], left_len: Int,
    right: InlineArray[Int64, MAX_ORDER + 1], right_len: Int,
    mut product: InlineArray[Int64, 2 * MAX_ORDER + 1]):
    for i in range(left_len + right_len - 1):
        product[i] = 0
    for i in range(left_len):
        for j in range(right_len):
            let at = i + j
            product[at] = (product[at] + left[i] * right[j]) % MODULUS

@export("bostan_mori_recurrence_term")
fn bostan_mori_recurrence_term(input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2:
        return -1
    let order_word = input[0]
    let index_word = input[1]
    if order_word < 1 or order_word > MAX_ORDER or index_word < 0
            or index_word > 1000000000000000000:
        return -1
    let order = Int(order_word)
    if length != 2 + 2 * order:
        return -1

    var numerator = InlineArray[Int64, MAX_ORDER + 1]()
    var initial = InlineArray[Int64, MAX_ORDER + 1]()
    var denominator = InlineArray[Int64, MAX_ORDER + 1]()
    denominator[0] = 1
    for i in range(order):
        let coefficient = input[2 + i]
        initial[i] = input[2 + order + i]
        if coefficient < 0 or coefficient >= MODULUS or initial[i] < 0 or initial[i] >= MODULUS:
            return -1
        denominator[i + 1] = (MODULUS - coefficient) % MODULUS

    var first_product = InlineArray[Int64, 2 * MAX_ORDER + 1]()
    bmr_convolve(initial, order, denominator, order + 1, mut first_product)
    for i in range(order):
        numerator[i] = first_product[i]

    var index = index_word
    while index > 0:
        var denominator_negative = InlineArray[Int64, MAX_ORDER + 1]()
        var numerator_product = InlineArray[Int64, 2 * MAX_ORDER + 1]()
        var denominator_product = InlineArray[Int64, 2 * MAX_ORDER + 1]()
        for i in range(order + 1):
            if i % 2 == 0 or denominator[i] == 0:
                denominator_negative[i] = denominator[i]
            else:
                denominator_negative[i] = MODULUS - denominator[i]
        bmr_convolve(numerator, order, denominator_negative, order + 1, mut numerator_product)
        bmr_convolve(denominator, order + 1, denominator_negative, order + 1, mut denominator_product)
        let parity = Int(index & 1)
        for i in range(order):
            numerator[i] = numerator_product[2 * i + parity]
        for i in range(order + 1):
            denominator[i] = denominator_product[2 * i]
        index >>= 1
    return numerator[0]
