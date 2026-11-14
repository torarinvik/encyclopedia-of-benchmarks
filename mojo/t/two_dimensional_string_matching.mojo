from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("two_dimensional_string_matching")
fn two_dimensional_string_matching(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 6 or length > 132: return -1
    let rv = input[0]; let cv = input[1]; let hv = input[2]; let wv = input[3]
    if rv < 1 or rv > 8 or cv < 1 or cv > 8 or hv < 1 or hv > rv or wv < 1 or wv > cv or length != c_size_t(4 + rv * cv + hv * wv): return -1
    let rows = Int(rv); let cols = Int(cv); let height = Int(hv); let width = Int(wv)
    var text = InlineArray[Int64, 64](fill=0)
    var pattern = InlineArray[Int64, 64](fill=0)
    for i in range(rows * cols):
        let value = input[4 + i]
        if value < 0 or value > 3: return -1
        text[i] = value
    for i in range(height * width):
        let value = input[4 + rows * cols + i]
        if value < 0 or value > 3: return -1
        pattern[i] = value
    var row_equal = InlineArray[Bool, 64](fill=False)
    for a in range(height):
        for b in range(height):
            var equal = True
            for x in range(width):
                if pattern[a * width + x] != pattern[b * width + x]: equal = False
            row_equal[8 * a + b] = equal
    var prefix = InlineArray[Int, 8](fill=0)
    for i in range(1, height):
        var q = prefix[i - 1]
        while q > 0 and not row_equal[8 * i + q]: q = prefix[q - 1]
        if row_equal[8 * i + q]: q += 1
        prefix[i] = q
    var marks = InlineArray[Bool, 512](fill=False)
    for row in range(rows):
        for col in range(cols - width + 1):
            for pr in range(height):
                var equal = True
                for x in range(width):
                    if text[row * cols + col + x] != pattern[pr * width + x]: equal = False
                marks[(8 * row + col) * 8 + pr] = equal
    var match_rows = InlineArray[Int64, 64](fill=0)
    var match_cols = InlineArray[Int64, 64](fill=0)
    var count = 0
    for col in range(cols - width + 1):
        var q = 0
        for row in range(rows):
            while q > 0 and not marks[(8 * row + col) * 8 + q]: q = prefix[q - 1]
            if marks[(8 * row + col) * 8 + q]: q += 1
            if q == height:
                match_rows[count] = Int64(row + 1 - height)
                match_cols[count] = Int64(col)
                count += 1
                q = prefix[height - 1]
    let bytes = 8 * (1 + 2 * count)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for word in range(1 + 2 * count):
        var value: Int64 = Int64(count)
        if word > 0:
            let i = (word - 1) // 2
            value = if (word & 1) != 0: match_rows[i] else: match_cols[i]
        var bits = UInt64(value)
        for byte in range(8):
            output[8 * word + byte] = UInt8(bits & 255)
            bits >>= 8
    return Int64(bytes)
