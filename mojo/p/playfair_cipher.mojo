from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("playfair_cipher")
fn playfair_cipher(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>157:return -1
    let op=v[0];let kl=v[1]
    if (op!=0 and op!=1) or kl<0 or kl>25:return -1
    let ti=Int(2+kl)
    if n<=c_size_t(ti):return -1
    let tl=v[ti]
    if tl<0 or tl>128 or tl%2!=0 or n!=c_size_t(ti+1+Int(tl)):return -1
    var square=InlineArray[UInt8,25](fill=0);var seen=InlineArray[Bool,26](fill=False);var sl=0
    for i in range(Int(kl)):
        let ch=v[2+i]
        if ch<65 or ch>90 or ch==74:return -1
        let ix=Int(ch-65)
        if not seen[ix]:square[sl]=UInt8(ch);sl+=1;seen[ix]=True
    for i in range(25):
        let ch=UInt8(65+i+ (1 if i>=9 else 0));let ix=Int(ch)-65
        if not seen[ix]:square[sl]=ch;sl+=1;seen[ix]=True
    var pos=InlineArray[Int32,26](fill=0)
    for i in range(25):pos[Int(square[i])-65]=Int32(i)
    var h=UInt64(14695981039346656037)
    for i in range(Int(tl)):
        let a=v[ti+1+i]
        if a<65 or a>90 or a==74:return -1
        if op==0 and i+1<Int(tl) and a==v[ti+2+i]:return -1
    for i in range(0,Int(tl),2):
        let aa=Int(pos[Int(v[ti+1+i])-65]);let bb=Int(pos[Int(v[ti+2+i])-65])
        let r1=aa//5;let c1=aa%5;let r2=bb//5;let c2=bb%5
        var oa=0;var ob=0
        if r1==r2:
            let d=1 if op==0 else 4
            oa=Int(square[r1*5+(c1+d)%5]);ob=Int(square[r2*5+(c2+d)%5])
        elif c1==c2:
            let d=1 if op==0 else 4
            oa=Int(square[((r1+d)%5)*5+c1]);ob=Int(square[((r2+d)%5)*5+c2])
        else:oa=Int(square[r1*5+c2]);ob=Int(square[r2*5+c1])
        h=(h^UInt64(oa))*UInt64(1099511628211);h=(h^UInt64(ob))*UInt64(1099511628211)
    return Int64(h & UInt64(0x7fffffffffffffff))
