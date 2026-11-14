from std.collections import List

fn nibble(value: UInt32) -> Int64:
    let table = UInt64(0x4332322132212110)
    let shift = Int(value & UInt32(15))*4
    return Int64((table >> shift) & UInt64(15))

fn recursive_nibbles(value: UInt32) -> Int64:
    if value < UInt32(16): return nibble(value)
    return nibble(value)+recursive_nibbles(value >> 4)

fn byte_count(value: UInt32) -> Int64:
    return nibble(value)+nibble(value >> 4)

fn selected_count(algorithm: Int, input: UInt32) -> Int64:
    var value = input
    var count = Int64(0)
    if algorithm == 0:
        while value != UInt32(0):
            value &= value-UInt32(1)
            count += 1
    elif algorithm == 1:
        value = ((value & UInt32(0xAAAAAAAA)) >> 1) + (value & UInt32(0x55555555))
        value = ((value & UInt32(0xCCCCCCCC)) >> 2) + (value & UInt32(0x33333333))
        value = ((value & UInt32(0xF0F0F0F0)) >> 4) + (value & UInt32(0x0F0F0F0F))
        value = ((value & UInt32(0xFF00FF00)) >> 8) + (value & UInt32(0x00FF00FF))
        value = ((value & UInt32(0xFFFF0000)) >> 16) + (value & UInt32(0x0000FFFF))
        count = Int64(value)
    elif algorithm == 2:
        count = recursive_nibbles(value)
    elif algorithm == 3:
        for _ in range(8):
            count += nibble(value)
            value = value >> 4
    elif algorithm == 4:
        count = byte_count(value)+byte_count(value >> 8)+byte_count(value >> 24)+byte_count(value >> 16)
    elif algorithm == 5:
        for _ in range(4):
            count += byte_count(value)
            value = value >> 8
    else:
        while value != UInt32(0):
            count += Int64(value & UInt32(1))
            value = value >> 1
    return count

@export("automotive_bitcount")
fn automotive_bitcount(iterations: Int64) abi("C") -> Int64:
    if iterations < 0 or iterations > 1125000: return -1
    var seeds = List[UInt32](capacity=7)
    seeds.append(16839); seeds.append(18985); seeds.append(21520); seeds.append(3905)
    seeds.append(10113); seeds.append(8672); seeds.append(21285)
    var result = Int64(0)
    for algorithm in range(7):
        var seed = seeds[algorithm]
        var total = Int64(0)
        for _ in range(Int(iterations)):
            total += selected_count(algorithm, seed)
            seed += UInt32(13)
        result += Int64(algorithm+1)*total
    return result
