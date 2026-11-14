from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

# VersaBench direct-table profile; retain benchmarks/0-9/8b10b/LICENSE.txt.
@export("versabench_8b10b")
fn versabench_8b10b(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if length > 160 or (length > 0 and values == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    let n = Int(length)
    for i in range(n):
        if values[i] < 0 or values[i] > 511: return -1
    let count = 0 if n == 0 else 1 + (n - 1) // 128
    let required = 9 * count
    if required > 0 and (output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required)): return -2

    var table5 = InlineArray[Int, 32]()
    table5[0]=0x0d80; table5[1]=0x05a2; table5[2]=0x0c60; table5[3]=0x0cc0
    table5[4]=0x0ca0; table5[5]=0x10a2; table5[6]=0x10c2; table5[7]=0x10e0
    table5[8]=0x0d20; table5[9]=0x1122; table5[10]=0x1142; table5[11]=0x1160
    table5[12]=0x1182; table5[13]=0x11a0; table5[14]=0x11c0; table5[15]=0x05e0
    table5[16]=0x0e20; table5[17]=0x1222; table5[18]=0x1242; table5[19]=0x1260
    table5[20]=0x1282; table5[21]=0x12a0; table5[22]=0x12c0; table5[23]=0x06e0
    table5[24]=0x1302; table5[25]=0x1320; table5[26]=0x1340; table5[27]=0x0760
    table5[28]=0x0380; table5[29]=0x07a0; table5[30]=0x0e80; table5[31]=0x06a2
    var table3 = InlineArray[Int, 8]()
    table3[0]=0x0c08; table3[1]=0x0c04; table3[2]=0x1009; table3[3]=0x100c
    table3[4]=0x1011; table3[5]=0x1014; table3[6]=0x0018; table3[7]=0x041c
    var disparity = 0
    var used = 0
    for pass_index in range(n):
        for index in range(n):
            let word = Int(values[index])
            let control = word >> 8
            let five = (word & 255) >> 3
            let three = word & 7
            var a = table5[five]
            var b = table3[three]
            if control == 1 and five == 7: a = 0x04e2
            if control == 1:
                if three >= 2 and three <= 5: b = (b & ~0x1000) | 0x0800
                elif three == 7: b = 0x040d
            var encoded = a & 0x03e2
            if (a & 0x1000) == 0:
                if disparity != (1 if (a & 0x0800) != 0 else 0): encoded ^= 0x03e2
                if (a & 0x0400) != 0: disparity ^= 1
            var lower = b & 0x001d
            if (b & 0x1000) == 0:
                if disparity != (1 if (b & 0x0800) != 0 else 0): lower ^= 0x001d
                if (b & 0x0400) != 0: disparity ^= 1
            encoded |= lower
            if pass_index == n - 1 and index % 128 == 0:
                for digit in range(8):
                    let nibble = (encoded >> (4 * (7 - digit))) & 15
                    output[used] = UInt8(nibble + (48 if nibble < 10 else 55))
                    used += 1
                output[used] = 10
                used += 1
    return Int64(used)
