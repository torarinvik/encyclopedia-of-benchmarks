@export("logarithm")
fn logarithm(x:Int64) abi("C")->Int64:
    if x<1 or x>4294967295:return -1
    var v=UInt32(x);var r:Int64=0
    if (v&UInt32(0xffff0000))!=0:v>>=16;r+=16
    if (v&UInt32(0x0000ff00))!=0:v>>=8;r+=8
    if (v&UInt32(0x000000f0))!=0:v>>=4;r+=4
    if (v&UInt32(0x0000000c))!=0:v>>=2;r+=2
    if (v&UInt32(2))!=0:r+=1
    return r
