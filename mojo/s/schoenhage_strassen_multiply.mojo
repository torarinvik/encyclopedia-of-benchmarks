# Draft of a bounded radix-2 Schönhage–Strassen transform.
# Algorithm provenance and CC0 license: package README and LICENSE.txt.
# Draft only; compilation and arithmetic results have not been verified.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

# Rotate a coefficient block in Z[x]/(x^width + 1). Indices and signs
# reflect x^width = -1; the source and destination arrays must differ.
fn ss_rotate(mut destination: InlineArray[Int64, 4096], destination_start: Int,
             source: InlineArray[Int64, 4096], source_start: Int,
             width: Int, shift: Int):
    let turns = shift // width
    let displacement = shift % width
    for index in range(width):
        let sum = index + displacement
        let position = sum % width
        var value = source[source_start + index]
        if ((turns + sum // width) & 1) != 0: value = -value
        destination[destination_start + position] = value

# The roots are powers of x. A bit-reversed phase schedule gives the same
# forward butterfly order as the documented radix-2 negacyclic transform.
fn ss_transform(mut values: InlineArray[Int64, 4096], log_length: Int,
                log_block: Int, inverse: Bool):
    let length = 1 << log_length
    let width = 1 << log_block
    var increments = InlineArray[Int, 16](fill=0)
    for bit in range(log_length - 1):
        var delta = (1 << (log_length - 2 - bit)) + (1 << (log_length - 1 - bit)) - length // 2
        if delta < 0: delta += length
        if length == width: delta *= 2
        if 2 * length == width: delta *= 4
        increments[bit] = delta
    var rotated = InlineArray[Int64, 4096](fill=0)
    var temporary = InlineArray[Int64, 4096](fill=0)
    var distance = length // 2
    if inverse: distance = 1
    while distance > 0 and distance < length:
        var phase = 0
        var group = 0
        var sequence = 0
        while group < length:
            for left_block in range(group, group + distance):
                let left = left_block * width
                let right = (left_block + distance) * width
                if inverse:
                    for j in range(width):
                        let x = values[left + j]
                        let y = values[right + j]
                        values[left + j] = x + y
                        temporary[j] = x - y
                    ss_rotate(rotated, 0, temporary, 0, width, phase)
                    for j in range(width): values[right + j] = rotated[j]
                else:
                    ss_rotate(rotated, 0, values, right, width, phase)
                    for j in range(width):
                        let x = values[left + j]
                        let y = rotated[j]
                        values[left + j] = x + y
                        values[right + j] = x - y
            group += 2 * distance
            if group < length:
                sequence += 1
                var trailing = 0
                var bits = sequence
                while (bits & 1) == 0:
                    trailing += 1
                    bits >>= 1
                if inverse: phase -= increments[trailing]
                else: phase += increments[trailing]
                if phase < 0: phase += 2 * width
                if phase >= 2 * width: phase -= 2 * width
        if inverse: distance *= 2
        else: distance //= 2
    if inverse:
        for i in range(length * width): values[i] //= length

# Multiply coefficient vectors in x^N+1 (or x^N-1 at the outermost level).
# For small N use the defining wrapped convolution; larger instances split
# into blocks, transform, recursively multiply, invert, and recombine.
fn ss_product(mut left: InlineArray[Int64, 4096], right: InlineArray[Int64, 4096],
              exponent: Int, negacyclic: Bool):
    let size = 1 << exponent
    if exponent <= 5:
        var product = InlineArray[Int64, 4096](fill=0)
        for i in range(size):
            for j in range(size):
                let degree = i + j
                let term = left[i] * right[j]
                if degree >= size and negacyclic:
                    product[degree - size] -= term
                else:
                    product[degree % size] += term
        for i in range(size): left[i] = product[i]
        return

    let l = (exponent + 1) // 2
    let m = exponent // 2
    let count = 1 << l
    let width = 1 << m
    let expanded_width = 2 * width
    var transformed_left = InlineArray[Int64, 4096](fill=0)
    var transformed_right = InlineArray[Int64, 4096](fill=0)
    var block = InlineArray[Int64, 4096](fill=0)
    for i in range(count):
        for j in range(expanded_width): block[j] = 0
        for j in range(width): block[j] = left[i * width + j]
        var shift = 0
        if negacyclic: shift = i * (expanded_width // count)
        ss_rotate(transformed_left, i * expanded_width, block, 0, expanded_width, shift)
        for j in range(width): block[j] = right[i * width + j]
        ss_rotate(transformed_right, i * expanded_width, block, 0, expanded_width, shift)
    ss_transform(transformed_left, l, m + 1, False)
    ss_transform(transformed_right, l, m + 1, False)
    for i in range(count):
        var child_left = InlineArray[Int64, 4096](fill=0)
        var child_right = InlineArray[Int64, 4096](fill=0)
        for j in range(expanded_width):
            child_left[j] = transformed_left[i * expanded_width + j]
            child_right[j] = transformed_right[i * expanded_width + j]
        ss_product(child_left, child_right, m + 1, True)
        for j in range(expanded_width): transformed_left[i * expanded_width + j] = child_left[j]
    ss_transform(transformed_left, l, m + 1, True)
    if negacyclic:
        var unrotated = InlineArray[Int64, 4096](fill=0)
        for i in range(count):
            let phase = i * (expanded_width // count)
            let reverse_phase = (2 * expanded_width - phase % (2 * expanded_width)) % (2 * expanded_width)
            ss_rotate(unrotated, i * expanded_width, transformed_left, i * expanded_width,
                      expanded_width, reverse_phase)
        for i in range(count * expanded_width): transformed_left[i] = unrotated[i]
    for i in range(count):
        let previous = (i + count - 1) % count
        for j in range(width):
            let low = transformed_left[i * expanded_width + j]
            let high = transformed_left[previous * expanded_width + width + j]
            if negacyclic and i == 0: left[i * width + j] = low - high
            else: left[i * width + j] = low + high

@export("schoenhage_strassen_multiply")
fn schoenhage_strassen_multiply(input: UnsafePointer[Int64, ImmutAnyOrigin],
                                length: c_size_t,
                                output: UnsafePointer[UInt8, MutAnyOrigin],
                                capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1027: return -1
    if input[0] != 513: return -1
    var left = InlineArray[Int64, 4096](fill=0)
    var right = InlineArray[Int64, 4096](fill=0)
    for i in range(513):
        let a = input[1 + i]
        let b = input[514 + i]
        if a < 0 or a > 1 or b < 0 or b > 1: return -1
        left[i] = a
        right[i] = b
    if left[512] != 1 or right[512] != 1: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 129: return -2
    ss_product(left, right, 11, False)
    var encoded = InlineArray[UInt8, 129](fill=0)
    var carry: Int64 = 0
    for i in range(1025):
        let value = left[i] + carry
        if (value & 1) != 0: encoded[128 - i // 8] |= UInt8(1 << (i % 8))
        carry = value // 2
    var position = 1025
    while carry > 0:
        if (carry & 1) != 0: encoded[128 - position // 8] |= UInt8(1 << (position % 8))
        carry //= 2
        position += 1
    for i in range(129): output[i] = encoded[i]
    return 129
