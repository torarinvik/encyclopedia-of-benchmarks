# Independent NetBench CRC profile; see package LICENSE_NOTICE.txt.
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("netbench_crc")
fn netbench_crc(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length > 256 or (length > 0 and input == UnsafePointer[Int64, ImmutAnyOrigin]()):
        return -1
    for i in range(Int(length)):
        if input[i] < 0 or input[i] > 255:
            return -1
    var table = InlineArray[UInt64, 256](fill=0)
    for byte in range(256):
        var remainder = UInt64(byte) << 24
        for _ in range(8):
            if (remainder & 0x80000000) != 0:
                remainder = (remainder << 1) ^ 0x04c11db7
            else:
                remainder <<= 1
            remainder &= 0xffffffff
        table[byte] = remainder
    var crc: UInt64 = 0
    for i in range(Int(length)):
        let index = Int(((crc >> 24) ^ UInt64(input[i])) & 255)
        crc = ((crc << 8) ^ table[index]) & 0xffffffff
    return Int64(crc)
