from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn grundy(pos:Int,memo:UnsafePointer[Int64,MutAnyOrigin],moves:UnsafePointer[Int64,ImmutAnyOrigin],mc:Int)->Int64:
    if memo[pos]!= -1:return memo[pos]
    if pos==0:memo[0]=0;return 0
    var reached=InlineArray[Bool,33](fill=False)
    for i in range(mc):
        let step=Int(moves[i])
        if step<=pos:
            let g=grundy(pos-step,memo,moves,mc);reached[Int(g)]=True
    var mex=0
    while mex<=32 and reached[mex]:mex+=1
    memo[pos]=Int64(mex);return Int64(mex)
@export("sprague_grundy_theorem")
fn sprague_grundy_theorem(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>34:return -1
    let pos=v[0];let mc=v[1]
    if pos<0 or pos>64 or mc<0 or mc>32 or n!=c_size_t(2+mc):return -1
    for i in range(Int(mc)):if v[2+i]<1 or v[2+i]>32:return -1
    var memo=InlineArray[Int64,65](fill= -1)
    return grundy(Int(pos),memo.unsafe_ptr(),UnsafePointer[Int64,ImmutAnyOrigin](v.unsafe_ptr().offset(2)),Int(mc))
