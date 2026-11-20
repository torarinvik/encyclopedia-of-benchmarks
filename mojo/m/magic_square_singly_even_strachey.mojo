from std.collections import InlineArray

fn magic_square_singly_even_hash_byte(hash: UInt64, byte: UInt8) -> UInt64:
    return (hash ^ UInt64(byte)) * 0x100000001b3

@export("magic_square_singly_even_strachey")
fn magic_square_singly_even_strachey(n: Int64) abi("C") -> Int64:
    if n < 6 or n > 30 or n % 4 != 2: return -1
    let order = Int(n)
    let half = order / 2
    let k = half / 2
    let block_size = half * half
    var odd = InlineArray[Int32, 900](fill=0)
    var square = InlineArray[Int32, 900](fill=0)

    var row = 0
    var column = half / 2
    odd[row * 30 + column] = 1
    for value in range(2, block_size + 1):
        let next_row = (row - 1 + half) % half
        let next_column = (column + 1) % half
        if odd[next_row * 30 + next_column] == 0:
            row = next_row
            column = next_column
        else:
            row = (row + 1) % half
        odd[row * 30 + column] = Int32(value)

    for r in range(half):
        for c in range(half):
            let value = odd[r * 30 + c]
            square[r * 30 + c] = value
            square[r * 30 + half + c] = value + Int32(2 * block_size)
            square[(half + r) * 30 + c] = value + Int32(3 * block_size)
            square[(half + r) * 30 + half + c] = value + Int32(block_size)

    for r in range(half):
        for c in range(k):
            let top = r * 30 + c
            let bottom = (half + r) * 30 + c
            let saved = square[top]; square[top] = square[bottom]; square[bottom] = saved
        for c in range(half - (k - 1), half):
            let top = r * 30 + half + c
            let bottom = (half + r) * 30 + half + c
            let saved = square[top]; square[top] = square[bottom]; square[bottom] = saved

    let first_middle_top = k * 30
    let first_middle_bottom = (half + k) * 30
    let saved_first = square[first_middle_top]
    square[first_middle_top] = square[first_middle_bottom]
    square[first_middle_bottom] = saved_first
    let center_top = k * 30 + k
    let center_bottom = (half + k) * 30 + k
    let saved_center = square[center_top]
    square[center_top] = square[center_bottom]
    square[center_bottom] = saved_center

    var hash: UInt64 = 0xcbf29ce484222325
    hash = magic_square_singly_even_hash_byte(hash, UInt8(order))
    for r in range(order):
        for c in range(order):
            let bits = UInt32(square[r * 30 + c])
            for b in range(4): hash = magic_square_singly_even_hash_byte(hash, UInt8((bits >> UInt32(b * 8)) & 255))
    return Int64(hash & 0x7fffffffffffffff)
