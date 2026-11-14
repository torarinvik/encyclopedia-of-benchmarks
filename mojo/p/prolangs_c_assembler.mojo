# (c) William Landi 1991
# Permission to use this code is granted as long as the copyright
# notice remains in place.
# Clean-room bounded adaptation of the documented two-pass assembler behavior.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("prolangs_c_assembler")
fn prolangs_c_assembler(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 9 or length > 65: return -1
    if input[0] < 2 or input[0] > 16: return -1
    let n = Int(input[0])
    if length != c_size_t(1+4*n): return -1
    var op = InlineArray[Int64, 16](fill=0)
    var label = InlineArray[Int64, 16](fill=0)
    var kind = InlineArray[Int64, 16](fill=0)
    var operand = InlineArray[Int64, 16](fill=0)
    var address = InlineArray[Int64, 16](fill=0)
    var size = InlineArray[Int64, 16](fill=0)
    var code = InlineArray[Int64, 16](fill=0)
    var defined = InlineArray[Bool, 17](fill=False)
    var symbols = InlineArray[Int64, 17](fill=0)
    for i in range(n):
        let p = 1+4*i
        if input[p] < 0 or input[p] > 11 or input[p+1] < 0 or input[p+1] > 16 or input[p+2] < 0 or input[p+2] > 5 or input[p+3] < 0 or input[p+3] > 0xffffff: return -1
        op[i] = input[p]; label[i] = input[p+1]; kind[i] = input[p+2]; operand[i] = input[p+3]
    if op[0] != 0 or op[n-1] != 1 or label[0] == 0 or kind[0] != 0 or operand[0] > 0xfffff: return -1
    if label[n-1] != 0 or kind[n-1] != 0 or operand[n-1] != 0: return -1
    for i in range(1,n-1):
        if op[i] == 0 or op[i] == 1: return -1
    let start = operand[0]
    var location = start
    defined[Int(label[0])] = True; symbols[Int(label[0])] = start
    for i in range(n):
        address[i] = location
        if i > 0 and label[i] != 0:
            let id = Int(label[i])
            if defined[id] or location >= 0x100000: return -1
            defined[id] = True; symbols[id] = location
        if op[i] == 0:
            if i != 0: return -1
        elif op[i] == 1:
            if i != n-1: return -1
        elif op[i] == 2 or op[i] == 3:
            if kind[i] != 0 or operand[i] > 256: return -1
            size[i] = operand[i]
            if op[i] == 3: size[i] *= 3
        elif op[i] == 4:
            if kind[i] != 0: return -1
            size[i] = 3
        elif op[i] >= 5 and op[i] <= 8:
            if not ((kind[i] == 1 and operand[i] <= 4095) or ((kind[i] == 2 or kind[i] == 3) and operand[i] >= 1 and operand[i] <= 16)): return -1
            size[i] = 3
        elif op[i] == 9:
            if kind[i] != 0 or operand[i] != 0: return -1
            size[i] = 3
        elif op[i] == 10:
            if kind[i] != 4 or operand[i] > 5: return -1
            size[i] = 2
        else:
            if kind[i] != 5 or (operand[i] >> 4) > 5 or (operand[i] & 15) > 5: return -1
            size[i] = 2
        if i > 0:
            if location > 0x100000-size[i]: return -1
            location += size[i]
    for i in range(1,n-1):
        if op[i] == 4: code[i] = operand[i]
        elif op[i] >= 5 and op[i] <= 8:
            var base: Int64 = 0
            if op[i] == 6: base = 0x0c
            elif op[i] == 7: base = 0x18
            elif op[i] == 8: base = 0x3c
            var ni: Int64 = 1
            if kind[i] == 2: ni = 3
            elif kind[i] == 3: ni = 2
            var field = operand[i]
            var relative: Int64 = 0
            if kind[i] == 2 or kind[i] == 3:
                let id = Int(operand[i])
                if not defined[id]: return -1
                field = symbols[id] - (address[i]+3)
                if field < -2048 or field > 2047: return -1
                relative = 1; field &= 0xfff
            code[i] = (base | ni)*65536 + relative*8192 + field
        elif op[i] == 9: code[i] = 0x4f0000
        elif op[i] == 10: code[i] = 0xb400 | (operand[i] << 4)
        elif op[i] == 11: code[i] = 0x9000 | operand[i]
    var checksum = ((location-start)*257 + start*17) % 1000000007
    for i in range(n):
        checksum = (checksum*131 + (address[i]+1)*17 + code[i]*3 + size[i]) % 1000000007
    return checksum
