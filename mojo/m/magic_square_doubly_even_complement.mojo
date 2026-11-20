fn magic_square_doubly_even_hash_byte(hash: UInt64, byte: UInt8) -> UInt64:
    return (hash ^ UInt64(byte)) * 0x100000001b3

@export("magic_square_doubly_even_complement")
fn magic_square_doubly_even_complement(n: Int64) abi("C") -> Int64:
    if n < 4 or n > 64 or n % 4 != 0: return -1
    let order = Int(n)
    let ceiling = order * order + 1
    var hash: UInt64 = magic_square_doubly_even_hash_byte(0xcbf29ce484222325, UInt8(order))

    for row in range(order):
        for column in range(order):
            var value = row * order + column + 1
            let local_row = row % 4
            let local_column = column % 4
            if local_row == local_column or local_row + local_column == 3:
                value = ceiling - value
            let bits = UInt32(Int32(value))
            for byte_index in range(4):
                let byte = UInt8((bits >> UInt32(byte_index * 8)) & 255)
                hash = magic_square_doubly_even_hash_byte(hash, byte)
    return Int64(hash & 0x7fffffffffffffff)
