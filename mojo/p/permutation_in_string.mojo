from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn perm_adjust(mut diff:InlineArray[Int64,26],mut nonzero:Int,letter:Int,amount:Int64):
    if diff[letter]==0:nonzero+=1
    diff[letter]+=amount
    if diff[letter]==0:nonzero-=1
@export("permutation_in_string")
fn permutation_in_string(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>2050 or v[0]<0 or v[0]>1024 or v[1]<0 or v[1]>1024 or Int(n)!=2+Int(v[0])+Int(v[1]):return -1
    let m=Int(v[0]);let k=Int(v[1]);for i in range(2,Int(n)):if v[i]<97 or v[i]>122:return -1
    if m>k:return 0
    var diff=InlineArray[Int64,26](fill=0);var nonzero=0
    for i in range(m):
        let a=Int(v[2+i]-97);let b=Int(v[2+m+i]-97)
        perm_adjust(mut diff,mut nonzero,a,1)
        perm_adjust(mut diff,mut nonzero,b,-1)
    if nonzero==0:return 1
    for start in range(k-m):
        let out=Int(v[2+m+start]-97);let inc=Int(v[2+m+start+m]-97)
        perm_adjust(mut diff,mut nonzero,out,1)
        perm_adjust(mut diff,mut nonzero,inc,-1)
        if nonzero==0:return 1
    return 0
