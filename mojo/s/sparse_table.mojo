from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
comptime MAXN=12345
comptime LEVELS=14
comptime BAD:Int64= -1
@export("sparse_table")
fn sparse_table(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4 or n>12348:return BAD
    let nv=v[0]
    if nv<1 or nv>12344:return BAD
    let count=Int(nv)
    if n!=c_size_t(count+3) or n>12347:return BAD
    let leftv=v[count+1];let rightv=v[count+2]
    if leftv<0 or rightv<leftv or rightv>=nv:return BAD
    var vals=InlineArray[Int64,12345](fill=0);var logs=InlineArray[Int,12346](fill=0)
    for i in range(count):vals[i]=v[i+1]
    for size in range(2,count+1):logs[size]=logs[size/2]+1
    var table=InlineArray[Int32,172830](fill=0)
    for i in range(count):table[i]=Int32(i)
    let maxlevel=logs[count]
    for level in range(1,maxlevel+1):
        let span=1<<level;let half=span>>1
        for i in range(count-span+1):
            let first=Int(table[(level-1)*MAXN+i]);let second=Int(table[(level-1)*MAXN+i+half])
            table[level*MAXN+i]=Int32(if vals[first]<=vals[second] then first else second)
    let l=Int(leftv);let r=Int(rightv);let qlen=r-l+1;let level=logs[qlen];let span=1<<level
    let first=Int(table[level*MAXN+l]);let second=Int(table[level*MAXN+r-span+1])
    return Int64(if vals[first]<=vals[second] then first else second)
