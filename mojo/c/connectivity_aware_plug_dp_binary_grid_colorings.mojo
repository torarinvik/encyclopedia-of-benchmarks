from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime PLUG_CODE_STATES = 6561
comptime PLUG_MAX_STATES = 78732

fn plug_cell_color(code: Int) -> Int:
    if code == 0: return -1
    return 0 if code <= 4 else 1

fn plug_advance(input_codes: InlineArray[Int, 4], closed: Int, diagonal: Int,
                color: Int, row: Int, column: Int,
                mut output_codes: InlineArray[Int, 4],
                inout output_closed: Int, inout output_diagonal: Int) -> Bool:
    if (closed & (1 << color)) != 0: return False
    let above = input_codes[column]
    let left = 0 if column == 0 else input_codes[column - 1]
    if row != 0 and column != 0 and plug_cell_color(above) == color and plug_cell_color(left) == color and diagonal == color + 1: return False

    for slot in range(4): output_codes[slot] = input_codes[slot]
    output_codes[column] = 0
    let above_color = plug_cell_color(above)
    let above_label = (above if color == 0 else above - 4) if above_color == color else 0
    let left_label = (left if color == 0 else left - 4) if plug_cell_color(left) == color else 0
    var chosen_label = above_label if above_label != 0 else left_label
    if above_label != 0 and left_label != 0 and above_label != left_label:
        for slot in range(4):
            if color == 0 and output_codes[slot] == left_label: output_codes[slot] = above_label
            if color == 1 and output_codes[slot] == 4 + left_label: output_codes[slot] = 4 + above_label
        chosen_label = above_label
    if chosen_label == 0:
        var maximum = 0
        for slot in range(4):
            let code = output_codes[slot]
            if plug_cell_color(code) == color:
                let label = code if color == 0 else code - 4
                if label > maximum: maximum = label
        chosen_label = maximum + 1
    output_codes[column] = chosen_label if color == 0 else 4 + chosen_label

    output_closed = closed
    if above != 0 and above_color != color:
        var old_still_present = False
        var other_same_color = False
        for slot in range(4):
            let code = output_codes[slot]
            if code == above: old_still_present = True
            if plug_cell_color(code) == above_color and code != above: other_same_color = True
        if not old_still_present:
            if other_same_color: return False
            output_closed = closed | (1 << above_color)

    var mapping = InlineArray[Int, 9](fill=0)
    var next_black = 0
    var next_white = 0
    for slot in range(4):
        let code = output_codes[slot]
        if code == 0: continue
        if code <= 4:
            if mapping[code] == 0:
                next_black += 1
                mapping[code] = next_black
            output_codes[slot] = mapping[code]
        else:
            let key = code
            if mapping[key] == 0:
                next_white += 1
                mapping[key] = 4 + next_white
            output_codes[slot] = mapping[key]
    output_diagonal = 0 if above_color < 0 else above_color + 1
    return True

fn plug_encode(codes: InlineArray[Int, 4], closed: Int, diagonal: Int) -> Int:
    var powers = InlineArray[Int, 4](fill=0)
    powers[0] = 1; powers[1] = 9; powers[2] = 81; powers[3] = 729
    var code_key = 0
    for slot in range(4): code_key += codes[slot] * powers[slot]
    return (closed * 3 + diagonal) * PLUG_CODE_STATES + code_key

@export("connectivity_aware_plug_dp_binary_grid_colorings")
fn connectivity_aware_plug_dp_binary_grid_colorings(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1
    let rows_value = input[0]
    let columns_value = input[1]
    if rows_value < 2 or rows_value > 4 or columns_value < 2 or columns_value > 4: return -1
    let rows = Int(rows_value)
    let columns = Int(columns_value)
    var dp = InlineArray[Int64, PLUG_MAX_STATES](fill=0)
    var next = InlineArray[Int64, PLUG_MAX_STATES](fill=0)
    dp[0] = 1
    for cell in range(rows * columns):
        let row = cell // columns
        let column = cell % columns
        for state in range(PLUG_MAX_STATES): next[state] = 0
        for state in range(PLUG_MAX_STATES):
            if dp[state] == 0: continue
            var code_key = state % PLUG_CODE_STATES
            let flags = state // PLUG_CODE_STATES
            let diagonal = flags % 3
            let closed = flags // 3
            var codes = InlineArray[Int, 4](fill=0)
            for slot in range(4):
                codes[slot] = code_key % 9
                code_key //= 9
            for color in range(2):
                var output_codes = InlineArray[Int, 4](fill=0)
                var output_closed = 0
                var output_diagonal = 0
                if plug_advance(codes, closed, diagonal, color, row, column,
                                output_codes, inout output_closed, inout output_diagonal):
                    let destination = plug_encode(output_codes, output_closed, output_diagonal)
                    next[destination] += dp[state]
        for state in range(PLUG_MAX_STATES): dp[state] = next[state]

    var total: Int64 = 0
    for state in range(PLUG_MAX_STATES):
        if dp[state] == 0: continue
        var code_key = state % PLUG_CODE_STATES
        let closed = (state // PLUG_CODE_STATES) // 3
        var seen_black = InlineArray[Bool, 5](fill=False)
        var seen_white = InlineArray[Bool, 5](fill=False)
        var black_components = 0
        var white_components = 0
        for slot in range(4):
            let code = code_key % 9
            code_key //= 9
            if code >= 1 and code <= 4 and not seen_black[code]:
                seen_black[code] = True
                black_components += 1
            elif code >= 5 and code <= 8 and not seen_white[code - 4]:
                seen_white[code - 4] = True
                white_components += 1
        if ((closed & 1) != 0 and black_components == 0 or (closed & 1) == 0 and black_components == 1) and ((closed & 2) != 0 and white_components == 0 or (closed & 2) == 0 and white_components == 1):
            total += dp[state]
    return total
