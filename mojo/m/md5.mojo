from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

@export("md5")
fn md5(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if length > 4096 or (length != 0 and input == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    for i in range(Int(length)):
        if input[i] < 0 or input[i] > 255: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 16: return -2
    let shifts = InlineArray[UInt32, 64](
        7, 12, 17, 22, 7, 12, 17, 22,
        7, 12, 17, 22, 7, 12, 17, 22,
        5, 9, 14, 20, 5, 9, 14, 20,
        5, 9, 14, 20, 5, 9, 14, 20,
        4, 11, 16, 23, 4, 11, 16, 23,
        4, 11, 16, 23, 4, 11, 16, 23,
        6, 10, 15, 21, 6, 10, 15, 21,
        6, 10, 15, 21, 6, 10, 15, 21
    )
    let constants = InlineArray[UInt32, 64](
        3614090360, 3905402710, 606105819, 3250441966, 4118548399, 1200080426, 2821735955, 4249261313,
        1770035416, 2336552879, 4294925233, 2304563134, 1804603682, 4254626195, 2792965006, 1236535329,
        4129170786, 3225465664, 643717713, 3921069994, 3593408605, 38016083, 3634488961, 3889429448,
        568446438, 3275163606, 4107603335, 1163531501, 2850285829, 4243563512, 1735328473, 2368359562,
        4294588738, 2272392833, 1839030562, 4259657740, 2763975236, 1272893353, 4139469664, 3200236656,
        681279174, 3936430074, 3572445317, 76029189, 3654602809, 3873151461, 530742520, 3299628645,
        4096336452, 1126891415, 2878612391, 4237533241, 1700485571, 2399980690, 4293915773, 2240044497,
        1873313359, 4264355552, 2734768916, 1309151649, 4149444226, 3174756917, 718787259, 3951481745
    )
    let padded_len = ((Int(length) + 8) / 64 + 1) * 64
    let bit_length = UInt64(length) * UInt64(8)
    var padded = InlineArray[UInt8, 4160](fill=0)
    for i in range(Int(length)): padded[i] = UInt8(input[i])
    padded[Int(length)] = 128
    for b in range(8): padded[padded_len-8+b] = UInt8((bit_length >> UInt64(8*b)) & 255)
    var h0: UInt32 = 0x67452301
    var h1: UInt32 = 0xefcdab89
    var h2: UInt32 = 0x98badcfe
    var h3: UInt32 = 0x10325476
    for block in range(0, padded_len, 64):
        var words = InlineArray[UInt32, 16](fill=0)
        for i in range(16):
            var word: UInt32 = 0
            for b in range(4): word |= UInt32(padded[block+i*4+b]) << UInt32(8*b)
            words[i] = word
        var a=h0;var b=h1;var c=h2;var d=h3
        for index in range(64):
            var f: UInt32 = 0
            var g = 0
            if index < 16:
                f=(b&c)|((~b)&d);g=index
            elif index < 32:
                f=(d&b)|((~d)&c);g=(5*index+1)%16
            elif index < 48:
                f=b^c^d;g=(3*index+5)%16
            else:
                f=c^(b|(~d));g=(7*index)%16
            let sum=a+f+constants[index]+words[g]
            let amount=shifts[index]
            let rotated=(sum<<amount)|(sum>>(UInt32(32)-amount))
            let prior_d=d;d=c;c=b;b+=rotated;a=prior_d
        h0+=a;h1+=b;h2+=c;h3+=d
    var staged=InlineArray[UInt8,16](fill=0)
    let states=InlineArray[UInt32,4](h0,h1,h2,h3)
    for i in range(4):
        for byte in range(4):staged[i*4+byte]=UInt8((states[i]>>UInt32(8*byte))&255)
    for i in range(16):output[i]=staged[i]
    return 16
