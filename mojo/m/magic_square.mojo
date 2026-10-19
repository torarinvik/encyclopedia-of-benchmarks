from std.collections import InlineArray

fn magic_square_hash_byte(hash: UInt64, byte: UInt8) -> UInt64:
    return (hash ^ UInt64(byte)) * 0x100000001b3

@export("magic_square")
fn magic_square(n: Int64) abi("C") -> Int64:
    if n < 1 or n > 31 or n % 2 == 0: return -1
    let order = Int(n)
    var square = InlineArray[Int32, 961](fill=0)
    var row = order / 2; var column = order - 1
    square[row * 31 + column] = 1
    for value in range(2, order * order + 1):
        let next_row = (row - 1 + order) % order; let next_column = (column + 1) % order
        if square[next_row * 31 + next_column] == 0:
            row = next_row; column = next_column
        else:
            column = (column - 1 + order) % order
        square[row * 31 + column] = Int32(value)
    var hash: UInt64 = 0xcbf29ce484222325
    hash = magic_square_hash_byte(hash, UInt8(order))
    for r in range(order):
        for c in range(order):
            let bits = UInt32(square[r * 31 + c])
            for b in range(4): hash = magic_square_hash_byte(hash, UInt8((bits >> UInt32(b * 8)) & 255))
    return Int64(hash & 0x7fffffffffffffff)
