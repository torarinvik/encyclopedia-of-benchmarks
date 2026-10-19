from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn mm_eval(v:InlineArray[Int64,32],idx:Int,depth:Int,height:Int,maximizing:Bool)->Int64:
    if depth==height:return v[idx]
    let a=mm_eval(v,idx*2,depth+1,height,not maximizing);let b=mm_eval(v,idx*2+1,depth+1,height,not maximizing)
    if maximizing:return a if a>b else b
    return a if a<b else b
@export("minimax")
fn minimax(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>34:return -2147483649
    let count=v[0];let maxturn=v[1]
    if count<1 or count>32 or (count&(count-1))!=0 or (maxturn!=0 and maxturn!=1) or Int(n)!=Int(count)+2:return -2147483649
    var vals=InlineArray[Int64,32](fill=0)
    for i in range(Int(count)):
        if v[i+2] < -2147483648 or v[i+2]>2147483647:return -2147483649
        vals[i]=v[i+2]
    var height=0;var q=Int(count)
    while q>1:q>>=1;height+=1
    return mm_eval(vals,0,0,height,maxturn==1)
