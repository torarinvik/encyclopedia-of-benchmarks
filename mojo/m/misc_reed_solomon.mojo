# Reed–Solomon profile acknowledging Simon Rockliff's original contribution.
# See benchmarks/m/misc_reed_solomon/LICENSE.txt for its permission notice.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn rs_mul(a: Int, b: Int, powers: InlineArray[Int, 255], logs: InlineArray[Int, 256]) -> Int:
    if a == 0 or b == 0: return 0
    return powers[(logs[a] + logs[b]) % 255]

fn rs_div(a: Int, b: Int, powers: InlineArray[Int, 255], logs: InlineArray[Int, 256]) -> Int:
    if a == 0: return 0
    return powers[(logs[a] - logs[b] + 255) % 255]

@export("misc_reed_solomon")
fn misc_reed_solomon(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                     output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or (length != 189 and length != 191): return -1
    for i in range(188):
        if input[i] < 0 or input[i] > 255: return -1
    let errors = input[188]
    if (errors == 0 and length != 189) or (errors == 1 and length != 191) or (errors != 0 and errors != 1): return -1
    var error_position = -1
    if errors == 1:
        if input[189] < 0 or input[189] >= 204 or input[190] < 0 or input[190] > 255: return -1
        error_position = Int(input[189])
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 204: return -2

    var powers = InlineArray[Int, 255](fill=0)
    var logs = InlineArray[Int, 256](fill=-1)
    var value = 1
    for i in range(255):
        powers[i] = value
        logs[value] = i
        value <<= 1
        if (value & 256) != 0: value = value ^ 0x11d

    # Multiply the polynomial by each consecutive field root.
    var generator = InlineArray[Int, 17](fill=0)
    generator[0] = 1
    var degree = 0
    for root in range(1, 17):
        var j = degree + 1
        while j > 0:
            generator[j] = generator[j - 1] ^ rs_mul(generator[j], powers[root], powers, logs)
            j -= 1
        generator[0] = rs_mul(generator[0], powers[root], powers, logs)
        degree += 1

    var parity = InlineArray[Int, 16](fill=0)
    var index = 238
    while index >= 0:
        let symbol = Int(input[index - 51]) if index >= 51 else 0
        let feedback = symbol ^ parity[15]
        var j = 15
        while j > 0:
            parity[j] = parity[j - 1] ^ rs_mul(feedback, generator[j], powers, logs)
            j -= 1
        parity[0] = rs_mul(feedback, generator[0], powers, logs)
        index -= 1
    var word = InlineArray[Int, 204](fill=0)
    for i in range(188): word[i] = Int(input[i])
    for i in range(16): word[188 + i] = parity[i]
    if errors == 1: word[error_position] = Int(input[190])

    var first = 0
    var second = 0
    for i in range(255):
        var symbol = 0
        if i < 16: symbol = word[188 + i]
        elif i >= 67: symbol = word[i - 67]
        first = first ^ rs_mul(symbol, powers[i], powers, logs)
        second = second ^ rs_mul(symbol, powers[(2 * i) % 255], powers, logs)
    if first != 0 or second != 0:
        if first == 0: return -1
        let position = logs[rs_div(second, first, powers, logs)]
        if position < 0: return -1
        var actual = -1
        if position < 16: actual = 188 + position
        elif position >= 67: actual = position - 67
        if actual != error_position: return -1
        word[actual] = word[actual] ^ rs_div(first, powers[position], powers, logs)
    for i in range(204): output[i] = UInt8(word[i])
    return 204
