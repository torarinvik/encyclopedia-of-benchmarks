from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_DIM = 5
alias MAX_PAT_DIM = 4
alias MAX_INPUT = 196
alias MAX_MATCHES = 125

fn put_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    var bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8(bits & 255)
        bits >>= 8

fn same_rows(plane: InlineArray[Int64, 64], base: Int, left: Int, right: Int, width: Int) -> Bool:
    for column in range(width):
        if plane[base + left * width + column] != plane[base + right * width + column]: return False
    True

@export("three_dimensional_bird_baker_matching")
fn three_dimensional_bird_baker_matching(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 7 or length > MAX_INPUT: return -1
    let r0 = input[0]
    let c0 = input[1]
    let d0 = input[2]
    let pr0 = input[3]
    let pc0 = input[4]
    let pd0 = input[5]
    if r0 < 1 or r0 > 5 or c0 < 1 or c0 > 5 or d0 < 1 or d0 > 5 or pr0 < 1 or pr0 > 4 or pc0 < 1 or pc0 > 4 or pd0 < 1 or pd0 > 4 or pr0 > r0 or pc0 > c0 or pd0 > d0: return -1
    let rows = Int(r0)
    let columns = Int(c0)
    let depths = Int(d0)
    let p_rows = Int(pr0)
    let p_columns = Int(pc0)
    let p_depths = Int(pd0)
    let text_size = rows * columns * depths
    let pattern_size = p_rows * p_columns * p_depths
    if length != c_size_t(6 + text_size + pattern_size): return -1
    var text = InlineArray[Int64, 125]()
    var pattern = InlineArray[Int64, 64]()
    for i in range(text_size):
        text[i] = input[6 + i]
        if text[i] < 0 or text[i] > 3: return -1
    for i in range(pattern_size):
        pattern[i] = input[6 + text_size + i]
        if pattern[i] < 0 or pattern[i] > 3: return -1

    var plane_ids = InlineArray[Int32, 4]()
    var unique_planes = InlineArray[Int64, 64]()
    let plane_area = p_rows * p_columns
    var unique_count = 0
    for pz in range(p_depths):
        var found = unique_count
        for candidate in range(unique_count):
            var equal = True
            for i in range(plane_area):
                if unique_planes[candidate * 16 + i] != pattern[pz * plane_area + i]: equal = False
            if equal:
                found = candidate
                break
        if found == unique_count:
            for i in range(plane_area): unique_planes[unique_count * 16 + i] = pattern[pz * plane_area + i]
            unique_count += 1
        plane_ids[pz] = Int32(found)

    let row_starts = rows - p_rows + 1
    let column_starts = columns - p_columns + 1
    var labels = InlineArray[Int32, 125](fill=-1)
    for z in range(depths):
        for unique in range(unique_count):
            var marks = InlineArray[Bool, 100](fill=False)
            var prefix = InlineArray[Int32, 4]()
            for i in range(1, p_rows):
                var matched = Int(prefix[i - 1])
                while matched > 0 and not same_rows(unique_planes, unique * 16, i, matched, p_columns):
                    matched = Int(prefix[matched - 1])
                if same_rows(unique_planes, unique * 16, i, matched, p_columns): matched += 1
                prefix[i] = Int32(matched)
            for row in range(rows):
                for col in range(column_starts):
                    for p_row in range(p_rows):
                        var equal = True
                        for p_col in range(p_columns):
                            if text[(z * rows + row) * columns + col + p_col] != unique_planes[unique * 16 + p_row * p_columns + p_col]: equal = False
                        marks[(row * MAX_DIM + col) * MAX_PAT_DIM + p_row] = equal
            for col in range(column_starts):
                var matched = 0
                for row in range(rows):
                    while matched > 0 and not marks[(row * MAX_DIM + col) * MAX_PAT_DIM + matched]:
                        matched = Int(prefix[matched - 1])
                    if marks[(row * MAX_DIM + col) * MAX_PAT_DIM + matched]: matched += 1
                    if matched == p_rows:
                        labels[(z * MAX_DIM + row + 1 - p_rows) * MAX_DIM + col] = Int32(unique)
                        matched = Int(prefix[matched - 1])

    var depth_prefix = InlineArray[Int32, 4]()
    for i in range(1, p_depths):
        var matched = Int(depth_prefix[i - 1])
        while matched > 0 and plane_ids[i] != plane_ids[matched]: matched = Int(depth_prefix[matched - 1])
        if plane_ids[i] == plane_ids[matched]: matched += 1
        depth_prefix[i] = Int32(matched)
    var matches = InlineArray[Int64, 375]()
    var count = 0
    for row in range(row_starts):
        for col in range(column_starts):
            var matched = 0
            for z in range(depths):
                let token = labels[(z * MAX_DIM + row) * MAX_DIM + col]
                while matched > 0 and token != plane_ids[matched]: matched = Int(depth_prefix[matched - 1])
                if token == plane_ids[matched]: matched += 1
                if matched == p_depths:
                    matches[count * 3] = Int64(row)
                    matches[count * 3 + 1] = Int64(col)
                    matches[count * 3 + 2] = Int64(z + 1 - p_depths)
                    count += 1
                    matched = Int(depth_prefix[matched - 1])
    let output_bytes = 8 * (1 + 3 * count)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes): return -2
    put_le(output, 0, Int64(count))
    for i in range(3 * count): put_le(output, 8 * (i + 1), matches[i])
    Int64(output_bytes)
