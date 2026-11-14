from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn parameterized_store(output: UnsafePointer[UInt8, MutAnyOrigin], slot: Int, value: Int64):
    var bits = UInt64(value)
    for byte in range(8):
        output[8 * slot + byte] = UInt8(bits & 255)
        bits >>= 8

@export("parameterized_pattern_matching")
fn parameterized_pattern_matching(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 34: return -1
    let text_length = input[0]
    let pattern_length = input[1]
    if text_length < 0 or text_length > 24 or pattern_length < 1 or pattern_length > 8 or length != c_size_t(2 + text_length + pattern_length): return -1
    let n = Int(text_length)
    let m = Int(pattern_length)
    var symbols = InlineArray[Int, 32](fill=0)
    for i in range(n + m):
        let symbol = input[2 + i]
        if symbol < 0 or symbol > 15: return -1
        symbols[i] = Int(symbol)
    var pattern = InlineArray[Int, 8](fill=0)
    var previous = InlineArray[Int, 16](fill=-1)
    for i in range(m):
        let symbol = symbols[n + i]
        if previous[symbol] >= 0: pattern[i] = i - previous[symbol]
        previous[symbol] = i
    var matches = InlineArray[Int64, 24](fill=0)
    var count = 0
    if m <= n:
        for start in range(n - m + 1):
            var last = InlineArray[Int, 16](fill=-1)
            var match = True
            for i in range(m):
                let symbol = symbols[start + i]
                let code = if last[symbol] < 0: 0 else: i - last[symbol]
                if code != pattern[i]: match = False
                last[symbol] = i
            if match:
                matches[count] = Int64(start)
                count += 1
    let bytes = 8 * (count + 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    parameterized_store(output, 0, Int64(count))
    for i in range(count): parameterized_store(output, i + 1, matches[i])
    return Int64(bytes)
