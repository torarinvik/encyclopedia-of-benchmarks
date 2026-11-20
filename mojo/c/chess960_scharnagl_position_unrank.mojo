from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_POSITIONS = 960
alias MAX_INPUT_WORDS = 962

@export("chess960_scharnagl_position_unrank")
fn chess960_scharnagl_position_unrank(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > c_size_t(MAX_INPUT_WORDS): return -1
    let count_word = input[0]
    if count_word < 0 or count_word > MAX_POSITIONS or length != c_size_t(Int(count_word) + 1): return -1
    let count = Int(count_word)
    for item in range(count):
        let identifier = input[item + 1]
        if identifier < 0 or identifier >= MAX_POSITIONS: return -1
    let bytes = count * 8
    if count == 0: return 0
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for item in range(count):
        var remainder = UInt64(input[item + 1])
        let odd_bishop = Int(remainder % 4) * 2 + 1
        remainder = remainder // 4
        let even_bishop = Int(remainder % 4) * 2
        remainder = remainder // 4
        let queen_ordinal = Int(remainder % 6)
        let knight_ordinal = Int(remainder // 6)
        var pair_remainder = knight_ordinal
        var first_knight = 0
        while pair_remainder >= 4 - first_knight:
            pair_remainder -= 4 - first_knight
            first_knight += 1
        let second_knight = first_knight + 1 + pair_remainder
        var board = InlineArray[UInt8, 8](fill=0)
        board[odd_bishop] = UInt8(ord('B'))
        board[even_bishop] = UInt8(ord('B'))
        var open_files = InlineArray[Int, 8](fill=0)
        var open_count = 0
        for file in range(8):
            if board[file] == 0:
                open_files[open_count] = file
                open_count += 1
        board[open_files[queen_ordinal]] = UInt8(ord('Q'))
        open_count = 0
        for file in range(8):
            if board[file] == 0:
                open_files[open_count] = file
                open_count += 1
        board[open_files[first_knight]] = UInt8(ord('N'))
        board[open_files[second_knight]] = UInt8(ord('N'))
        let final_pieces = InlineArray[UInt8, 3](UInt8(ord('R')), UInt8(ord('K')), UInt8(ord('R')))
        var next_piece = 0
        for file in range(8):
            if board[file] == 0:
                board[file] = final_pieces[next_piece]
                next_piece += 1
        for file in range(8): output[item * 8 + file] = board[file]
    Int64(bytes)
