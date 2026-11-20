from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias KBD_BASE = Int64(1_000_000_000)
alias KBD_MAX_LIMBS = 8
alias KBD_MAX_OUTPUT = 129

fn kbd_trim(x: InlineArray[Int64, KBD_MAX_LIMBS], count_input: Int) -> Int:
    var count = count_input
    while count > 0 and x[count - 1] == 0:
        count -= 1
    return count

fn kbd_parse(text: UnsafePointer[Int64, ImmutAnyOrigin], start: Int, length: Int) -> (InlineArray[Int64, KBD_MAX_LIMBS], Int):
    var limbs = InlineArray[Int64, KBD_MAX_LIMBS](fill=0)
    var count = 0
    for at in range(length):
        var carry = text[start + at] - 48
        for i in range(count):
            carry += limbs[i] * 10
            limbs[i] = carry % KBD_BASE
            carry //= KBD_BASE
        if carry != 0:
            limbs[count] = carry
            count += 1
        if count == 0:
            count = 1
    return limbs, kbd_trim(limbs, count)

fn kbd_compare(a: InlineArray[Int64, KBD_MAX_LIMBS], na: Int,
               b: InlineArray[Int64, KBD_MAX_LIMBS], nb: Int) -> Int:
    if na != nb:
        return 1 if na > nb else -1
    for step in range(na):
        let i = na - 1 - step
        if a[i] != b[i]:
            return 1 if a[i] > b[i] else -1
    return 0

fn kbd_divide(a: InlineArray[Int64, KBD_MAX_LIMBS], na: Int,
              b: InlineArray[Int64, KBD_MAX_LIMBS], nb: Int) -> (InlineArray[Int64, KBD_MAX_LIMBS], Int, InlineArray[Int64, KBD_MAX_LIMBS], Int):
    var q = InlineArray[Int64, KBD_MAX_LIMBS](fill=0)
    var r = InlineArray[Int64, KBD_MAX_LIMBS](fill=0)
    if na == 0:
        return q, 0, r, 0
    if kbd_compare(a, na, b, nb) < 0:
        for i in range(na): r[i] = a[i]
        return q, 0, r, na
    if nb == 1:
        var rem: Int64 = 0
        for step in range(na):
            let i = na - 1 - step
            let current = rem * KBD_BASE + a[i]
            q[i] = current // b[0]
            rem = current % b[0]
        if rem != 0: r[0] = rem
        return q, kbd_trim(q, na), r, 1 if rem != 0 else 0

    var v = InlineArray[Int64, KBD_MAX_LIMBS](fill=0)
    var u = InlineArray[Int64, KBD_MAX_LIMBS + 1](fill=0)
    let scale = KBD_BASE // (b[nb - 1] + 1)
    var carry: Int64 = 0
    for i in range(nb):
        let current = b[i] * scale + carry
        v[i] = current % KBD_BASE
        carry = current // KBD_BASE
    carry = 0
    for i in range(na):
        let current = a[i] * scale + carry
        u[i] = current % KBD_BASE
        carry = current // KBD_BASE
    u[na] = carry
    let width = na - nb + 1
    for step in range(width):
        let j = width - 1 - step
        let numerator = u[j + nb] * KBD_BASE + u[j + nb - 1]
        var estimate = numerator // v[nb - 1]
        var rem_estimate = numerator % v[nb - 1]
        if estimate >= KBD_BASE:
            estimate = KBD_BASE - 1
            rem_estimate = numerator - estimate * v[nb - 1]
        while rem_estimate < KBD_BASE and estimate * v[nb - 2] > rem_estimate * KBD_BASE + u[j + nb - 2]:
            estimate -= 1
            rem_estimate += v[nb - 1]
        var borrow: Int64 = 0
        for i in range(nb):
            let product = estimate * v[i] + borrow
            let low = product % KBD_BASE
            borrow = product // KBD_BASE
            var difference = u[j + i] - low
            if difference < 0:
                difference += KBD_BASE
                borrow += 1
            u[j + i] = difference
        let top = u[j + nb] - borrow
        if top < 0:
            estimate -= 1
            carry = 0
            for i in range(nb):
                var total = u[j + i] + v[i] + carry
                if total >= KBD_BASE:
                    total -= KBD_BASE
                    carry = 1
                else:
                    carry = 0
                u[j + i] = total
            u[j + nb] = top + carry
        else:
            u[j + nb] = top
        q[j] = estimate
    carry = 0
    for step in range(nb):
        let i = nb - 1 - step
        let current = carry * KBD_BASE + u[i]
        r[i] = current // scale
        carry = current % scale
    return q, kbd_trim(q, width), r, kbd_trim(r, nb)

fn kbd_emit(x: InlineArray[Int64, KBD_MAX_LIMBS], count_input: Int,
            mut result: InlineArray[UInt8, KBD_MAX_OUTPUT], at_input: Int) -> Int:
    var count = kbd_trim(x, count_input)
    var at = at_input
    if count == 0:
        result[at] = 48
        return at + 1
    var value = x[count - 1]
    var power: Int64 = 1
    while value // power >= 10: power *= 10
    while power > 0:
        result[at] = UInt8(48 + value // power % 10)
        at += 1
        power //= 10
    while count > 1:
        count -= 1
        value = x[count - 1]
        power = KBD_BASE // 10
        while power > 0:
            result[at] = UInt8(48 + value // power % 10)
            at += 1
            power //= 10
    return at

@export("knuth_big_integer_division")
fn knuth_big_integer_division(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 130:
        return -1
    if input[0] < 1 or input[0] > 64 or input[1] < 1 or input[1] > 64:
        return -1
    let na_text = Int(input[0])
    let nb_text = Int(input[1])
    if Int(length) != 2 + na_text + nb_text:
        return -1
    for i in range(na_text):
        if input[2 + i] < 48 or input[2 + i] > 57: return -1
    for i in range(nb_text):
        if input[2 + na_text + i] < 48 or input[2 + na_text + i] > 57: return -1
    if (na_text > 1 and input[2] == 48) or (nb_text > 1 and input[2 + na_text] == 48) or (nb_text == 1 and input[2 + na_text] == 48):
        return -1
    let (a, na) = kbd_parse(input, 2, na_text)
    let (b, nb) = kbd_parse(input, 2 + na_text, nb_text)
    let (q, nq, r, nr) = kbd_divide(a, na, b, nb)
    var result = InlineArray[UInt8, KBD_MAX_OUTPUT](fill=0)
    var bytes = kbd_emit(q, nq, result, 0)
    result[bytes] = 58
    bytes += 1
    bytes = kbd_emit(r, nr, result, bytes)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < bytes:
        return -2
    for i in range(bytes): output[i] = result[i]
    return Int64(bytes)
