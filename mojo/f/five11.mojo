# Independent bounded BitBench packet-decoder profile; see package attribution.
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn bits(values: UnsafePointer[Int64, ImmutAnyOrigin], offset: Int, width: Int) -> Int64:
    var result = Int64(0)
    for i in range(width):
        let position = offset+i
        result = (result << 1) | ((values[position // 8] >> (7-position % 8)) & 1)
    return result

@export("five11")
fn five11(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 13523: return -1
    for i in range(Int(length)):
        if values[i] < 0 or values[i] > 255: return -1
    let packets = bits(values,0,16)
    if packets > 451: return -1
    let total_bits = Int(length)*8
    var result = Int64(0)
    for _ in range(10000):
        var position = 16
        var sum = Int64(0)
        for _ in range(Int(packets)):
            if position+5 > total_bits: return -1
            let channels = Int(bits(values,position,5))
            position += 5
            for _ in range(channels):
                if position+11 > total_bits: return -1
                sum += bits(values,position,11)
                position += 11
            let packet_bits = 5+11*channels
            position += (8-(packet_bits & 7)) & 7
            if position > total_bits: return -1
        result = sum
    return result
