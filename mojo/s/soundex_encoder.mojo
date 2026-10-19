from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn ascii_letter(x:Int64)->Bool:return (x>=65 and x<=90) or (x>=97 and x<=122)
fn sound_digit(input:Int64)->Int64:
    let x=if input>=65 and input<=90 then input+32 else input
    if x==97 or x==101 or x==105 or x==111 or x==117 or x==121:return 0
    if x==104 or x==119:return 8
    if x==98 or x==102 or x==112 or x==118:return 1
    if x==99 or x==103 or x==106 or x==107 or x==113 or x==115 or x==120 or x==122:return 2
    if x==100 or x==116:return 3
    if x==108:return 4
    if x==109 or x==110:return 5
    if x==114:return 6
    return -1
@export("soundex_encoder")
fn soundex_encoder(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>67:return -1
    let textn=v[0]
    if textn<1 or textn>64 or n>65 or n!=c_size_t(textn+1):return -1
    for i in range(Int(textn)):if not ascii_letter(v[i+1]):return -1
    var mapped=InlineArray[Int64,64](fill=0);var m=0
    for i in range(Int(textn)):
        let c=if v[i+1]>=65 and v[i+1]<=90 then v[i+1]+32 else v[i+1]
        if c==104 or c==119:continue
        let d=sound_digit(c)
        if m==0 or mapped[m-1]!=d:mapped[m]=d;m+=1
    var compact=InlineArray[Int64,64](fill=0);var k=0
    for i in range(m):if mapped[i]!=0:compact[k]=mapped[i];k+=1
    if k==0:return -1
    let first=if v[1]>=65 and v[1]<=90 then v[1]+32 else v[1]
    var start=0
    if compact[0]==sound_digit(first):
        if k==1:return -1
        start=1
    var outbuf=InlineArray[UInt8,4](fill=48)
    outbuf[0]=UInt8(if v[1]>=97 and v[1]<=122 then v[1]-32 else v[1])
    for i in range(3):
        let d=if start+i<k then compact[start+i] else 0
        outbuf[i+1]=UInt8(48+d)
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<4:return -2
    for i in range(4):o[i]=outbuf[i]
    return 4
