# CoyoteBench Huffbench, attributed to Scott Robert Ladd; see package LICENSE.txt.
from std.collections import InlineArray, List
from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

fn huff_adjust(frequency: InlineArray[Int, 512], mut heap: InlineArray[Int, 256],
               active: Int, position: Int):
    var parent = position
    let value = heap[parent-1]
    while parent <= active//2:
        var child = 2*parent
        if child < active and frequency[heap[child-1]] > frequency[heap[child]]: child += 1
        if frequency[value] < frequency[heap[child-1]]: break
        heap[parent-1] = heap[child-1]
        parent = child
    heap[parent-1] = value

fn huff_decimal(mut target: List[UInt8], mut value: Int):
    var reversed = InlineArray[UInt8, 10]()
    var count = 0
    while True:
        reversed[count] = UInt8(48 + value % 10)
        count += 1; value //= 10
        if value == 0: break
    while count > 0:
        count -= 1
        target.append(reversed[count])

fn huff_round(mut data: InlineArray[UInt8, 4096], inout compressed_length: Int,
              inout checksum: Int) -> Bool:
    var frequency = InlineArray[Int, 512](fill=0)
    var heap = InlineArray[Int, 256](fill=0)
    var links = InlineArray[Int, 512](fill=0)
    var code = InlineArray[UInt32, 256](fill=0)
    var width = InlineArray[Int, 256](fill=0)
    for i in range(4096): frequency[Int(data[i])] += 1
    var active = 0
    for symbol in range(256):
        if frequency[symbol] != 0:
            heap[active] = symbol; active += 1
    var position = active
    while position > 0:
        huff_adjust(frequency, heap, active, position)
        position -= 1
    while active > 1:
        active -= 1
        let first = heap[0]
        heap[0] = heap[active]
        huff_adjust(frequency, heap, active, 1)
        let parent = 256 + active
        frequency[parent] = frequency[heap[0]] + frequency[first]
        links[first] = parent; links[heap[0]] = -parent
        heap[0] = parent
        huff_adjust(frequency, heap, active, 1)
    links[256+active] = 0
    for symbol in range(256):
        if frequency[symbol] == 0: continue
        var parent = links[symbol]
        var bit = UInt32(1)
        var bits = UInt32(0)
        while parent != 0:
            if parent < 0:
                bits += bit
                parent = -parent
            parent = links[parent]
            bit <<= 1
            width[symbol] += 1
        code[symbol] = bits
    var packed = InlineArray[UInt8, 4097](fill=0)
    var used = 0
    var byte = UInt8(0)
    var bit_index = -1
    for i in range(4096):
        let symbol = Int(data[i])
        var mask = UInt32(1) << (width[symbol]-1)
        for _ in range(width[symbol]):
            if bit_index == 7:
                packed[used] = byte; used += 1; bit_index = 0; byte = 0
            else:
                bit_index += 1; byte <<= 1
            if (code[symbol] & mask) != 0: byte |= 1
            mask >>= 1
    byte <<= (7-bit_index)
    packed[used] = byte; used += 1
    var children = InlineArray[Int, 1024](fill=-1)
    var symbols = InlineArray[Int, 512](fill=-1)
    var nodes = 1
    for symbol in range(256):
        if frequency[symbol] == 0: continue
        var node = 0
        var bit = width[symbol]
        while bit > 0:
            bit -= 1
            let direction = Int((code[symbol] >> bit) & 1)
            let slot = 2*node+direction
            if children[slot] < 0:
                children[slot] = nodes; nodes += 1
            node = children[slot]
        symbols[node] = symbol
    var decoded = 0; var node = 0; var sum = 0
    for i in range(used):
        var bit = 8
        while bit > 0 and decoded < 4096:
            bit -= 1
            let direction = Int((packed[i] >> bit) & 1)
            node = children[2*node+direction]
            if node < 0: return False
            if symbols[node] >= 0:
                data[decoded] = UInt8(symbols[node])
                sum += symbols[node]; decoded += 1; node = 0
    if decoded != 4096: return False
    compressed_length = used; checksum = sum
    return True

@export("coyote_huffbench")
fn coyote_huffbench(passes: Int64, output: UnsafePointer[UInt8, MutAnyOrigin],
                    capacity: c_size_t) abi("C") -> Int64:
    if passes < 1 or passes > 30: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin](): return -2
    var data = InlineArray[UInt8, 4096]()
    var state = 1325
    for i in range(4096):
        var seed = state ^ 123459876
        let quotient = seed//127773
        seed = 16807*(seed-quotient*127773)-2836*quotient
        if seed < 0: seed += 2147483647
        let digit = seed % 32
        state = seed ^ 123459876
        data[i] = UInt8(65+digit if digit < 26 else 48+digit-26)
    var encoded_length = 0; var checksum = 0
    for _ in range(Int(passes)):
        if not huff_round(data, encoded_length, checksum): return -1
    var staged = List[UInt8]()
    for byte in "Huffbench passes=".as_bytes(): staged.append(byte)
    huff_decimal(staged, Int(passes))
    for byte in " compressed=".as_bytes(): staged.append(byte)
    huff_decimal(staged, encoded_length)
    for byte in " checksum=".as_bytes(): staged.append(byte)
    huff_decimal(staged, checksum)
    staged.append(10)
    if capacity < c_size_t(len(staged)): return -2
    for i in range(len(staged)): output[i] = staged[i]
    return Int64(len(staged))
