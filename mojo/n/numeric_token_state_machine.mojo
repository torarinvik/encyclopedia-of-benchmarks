# Independent bounded CoreMark state-machine profile; see package license notice.
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("numeric_token_state_machine")
fn numeric_token_state_machine(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 99: return -1
    let count = input[0]
    let step = input[1]
    let seed = input[2]
    if count < 1 or count > 96 or length != c_size_t(count + 3) or step < 1 or step > 16 or seed < 1 or seed > 255: return -1
    let n = Int(count)
    var text = InlineArray[Int64, 96](fill=0)
    for i in range(n):
        let value = input[3 + i]
        if value < 32 or value > 126: return -1
        if value == 44 and (i == 0 or i == n - 1): return -1
        if i > 0 and value == 44 and text[i - 1] == 44: return -1
        text[i] = value
    var selected = 0
    while selected < n:
        if text[selected] != 44:
            let changed = text[selected] ^ seed
            if changed == 0 or changed == 44: return -1
        selected += Int(step)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 64: return -2
    var finals = InlineArray[Int64, 8](fill=0)
    var transitions = InlineArray[Int64, 8](fill=0)
    for pass_index in range(2):
        if pass_index == 1:
            var i = 0
            while i < n:
                if text[i] != 44: text[i] ^= seed
                i += Int(step)
        var pos = 0
        while pos < n:
            var state = 0
            while pos < n and state != 1:
                let ch = text[pos]
                if ch == 44:
                    pos += 1
                    break
                let digit = ch >= 48 and ch <= 57
                if state == 0:
                    if digit: state = 4
                    elif ch == 43 or ch == 45: state = 2
                    elif ch == 46: state = 5
                    else:
                        state = 1
                        transitions[1] += 1
                    transitions[0] += 1
                elif state == 2:
                    if digit: state = 4
                    elif ch == 46: state = 5
                    else: state = 1
                    transitions[2] += 1
                elif state == 4:
                    if ch == 46:
                        state = 5
                        transitions[4] += 1
                    elif not digit:
                        state = 1
                        transitions[4] += 1
                elif state == 5:
                    if ch == 101 or ch == 69:
                        state = 3
                        transitions[5] += 1
                    elif not digit:
                        state = 1
                        transitions[5] += 1
                elif state == 3:
                    if ch == 43 or ch == 45: state = 6
                    else: state = 1
                    transitions[3] += 1
                elif state == 6:
                    if digit: state = 7
                    else: state = 1
                    transitions[6] += 1
                elif state == 7 and not digit:
                    state = 1
                    transitions[1] += 1
                pos += 1
            finals[state] += 1
    for state in range(8):
        let final_bits = UInt64(finals[state])
        let transition_bits = UInt64(transitions[state])
        for byte in range(4):
            output[8 * state + byte] = UInt8((final_bits >> (8 * byte)) & 255)
            output[8 * state + 4 + byte] = UInt8((transition_bits >> (8 * byte)) & 255)
    return 64
