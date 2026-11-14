from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn cube_cover(input: UnsafePointer[Int64, ImmutAnyOrigin], size: Int, care: Int, value: Int) -> Int:
    var cover = 0
    for term in range(size):
        if (term & care) == value:
            if input[1+term] == 0: return 0
            if input[1+term] == 1: cover |= 1 << term
    return cover

fn earlier(left: Int, right: Int, count: Int) -> Bool:
    for i in range(count):
        let bit = 1 << i
        if (left & bit) != (right & bit): return (left & bit) != 0
    return False

@export("quine_mccluskey_minimization")
fn quine_mccluskey_minimization(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 9: return -1
    if input[0] < 1 or input[0] > 3: return -1
    let n = Int(input[0]); let size = 1 << n
    if length != c_size_t(1 + size): return -1
    var on_mask = 0
    for i in range(size):
        if input[1+i] < 0 or input[1+i] > 2: return -1
        if input[1+i] == 1: on_mask |= 1 << i
    var cares = InlineArray[Int, 27](fill=0)
    var values = InlineArray[Int, 27](fill=0)
    var covers = InlineArray[Int, 27](fill=0)
    var literals = InlineArray[Int, 27](fill=0)
    var count = 0
    for care in range(size):
        for value in range(size):
            if (value & ~care) != 0: continue
            let cover = cube_cover(input, size, care, value)
            if cover == 0: continue
            var prime = True
            var bits = 0
            for variable in range(n):
                let bit = 1 << variable
                if (care & bit) != 0:
                    bits += 1
                    if cube_cover(input, size, care ^ bit, value & ~bit) != 0: prime = False
            if prime:
                cares[count] = care; values[count] = value
                covers[count] = cover; literals[count] = bits
                count += 1
    var terms = InlineArray[Int, 256](fill=99)
    var costs = InlineArray[Int, 256](fill=99)
    var choices = InlineArray[Int, 256](fill=0)
    terms[0] = 0; costs[0] = 0
    let states = 1 << size
    for prime in range(count):
        var state = states
        while state > 0:
            state -= 1
            if terms[state] == 99: continue
            let dest = state | covers[prime]
            if dest == state: continue
            let next_terms = terms[state] + 1
            let next_cost = costs[state] + literals[prime]
            let next_choices = choices[state] | (1 << prime)
            var better = next_terms < terms[dest]
            if next_terms == terms[dest]:
                better = next_cost < costs[dest]
                if next_cost == costs[dest]: better = earlier(next_choices, choices[dest], count)
            if better:
                terms[dest] = next_terms; costs[dest] = next_cost; choices[dest] = next_choices
    let chosen = choices[on_mask]
    let bytes = 8 * (1 + 2 * terms[on_mask])
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var words = InlineArray[Int64, 17](fill=0)
    words[0] = Int64(terms[on_mask])
    var cursor = 1
    for i in range(count):
        if (chosen & (1 << i)) != 0:
            words[cursor] = Int64(cares[i]); words[cursor+1] = Int64(values[i])
            cursor += 2
    for i in range(cursor):
        let bits = UInt64(words[i])
        for b in range(8): output[8*i+b] = UInt8((bits >> (8*b)) & 255)
    return Int64(bytes)
