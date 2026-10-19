from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn tr_cont(b:UInt8)->Bool:return b>=128 and b<=191
fn tr_decode(b:InlineArray[UInt8,1024],n:Int,i:Int,inout cp:Int,inout width:Int)->Bool:
    let x=b[i]
    if x<=127:cp=Int(x);width=1;return True
    if x>=194 and x<=223:
        if i+1>=n or not tr_cont(b[i+1]):return False
        cp=((Int(x)&31)<<6)|(Int(b[i+1])&63);width=2;return True
    if x>=224 and x<=239:
        if i+2>=n:return False
        let y=b[i+1];let z=b[i+2]
        if not tr_cont(y) or not tr_cont(z) or (x==224 and y<160) or (x==237 and y>=160):return False
        cp=((Int(x)&15)<<12)|((Int(y)&63)<<6)|(Int(z)&63);width=3;return True
    if x>=240 and x<=244:
        if i+3>=n:return False
        let y=b[i+1];let z=b[i+2];let w=b[i+3]
        if not tr_cont(y) or not tr_cont(z) or not tr_cont(w) or (x==240 and y<144) or (x==244 and y>143):return False
        cp=((Int(x)&7)<<18)|((Int(y)&63)<<12)|((Int(z)&63)<<6)|(Int(w)&63);width=4;return True
    return False
fn tr_map(cp:Int)->Int:
    if cp==0x131:return 105
    if cp==0x130:return 73
    if cp==0xfc:return 117
    if cp==0xdc:return 85
    if cp==0xf6:return 111
    if cp==0xd6:return 79
    if cp==0x15f:return 115
    if cp==0x15e:return 83
    if cp==0xe7:return 99
    if cp==0xc7:return 67
    if cp==0x11f:return 103
    if cp==0x11e:return 71
    return 0
@export("turkish_to_latin_conversion")
fn turkish_to_latin_conversion(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>1025:return -1
    let size=a[0]
    if size<0 or size>1024 or n!=c_size_t(size+1):return -1
    var bytes=InlineArray[UInt8,1024]()
    for i in range(Int(size)):
        if a[i+1]<0 or a[i+1]>255:return -1
        bytes[i]=UInt8(a[i+1])
    var outlen=0;var i=0
    while i<Int(size):
        var cp=0;var width=0
        if not tr_decode(bytes,Int(size),i,cp,width):return -1
        outlen+=1 if tr_map(cp)!=0 else width;i+=width
    if cap<c_size_t(outlen) or (outlen>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var staged=InlineArray[UInt8,1024]();var written=0;i=0
    while i<Int(size):
        var cp=0;var width=0;let _=tr_decode(bytes,Int(size),i,cp,width);let mapped=tr_map(cp)
        if mapped!=0:staged[written]=UInt8(mapped);written+=1
        else:
            for j in range(width):staged[written]=bytes[i+j];written+=1
        i+=width
    for j in range(written):o[j]=staged[j]
    return Int64(written)
