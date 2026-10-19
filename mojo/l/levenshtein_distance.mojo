from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("levenshtein_distance")
fn levenshtein_distance(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>512:return -1
    let a=v[0];let b=v[1]
    if a<0 or a>255 or b<0 or b>255 or n!=c_size_t(2+a+b):return -1
    for i in range(Int(a)):
        if v[2+i]<0 or v[2+i]>127:return -1
    for i in range(Int(b)):
        if v[2+Int(a)+i]<0 or v[2+Int(a)+i]>127:return -1
    var row=InlineArray[Int64,256](fill=0)
    for j in range(Int(b)+1):row[j]=Int64(j)
    for ri in range(1,Int(a)+1):
        var diagonal=row[0];row[0]=Int64(ri)
        for j in range(1,Int(b)+1):
            let above=row[j];let deletion=above+1;let insertion=row[j-1]+1
            let sub=diagonal+Int64(v[1+ri]!=v[1+Int(a)+j])
            row[j]=min(min(deletion,insertion),sub);diagonal=above
    return row[Int(b)]
