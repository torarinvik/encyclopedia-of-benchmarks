from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("kth_lexicographic_permutation")
fn kth_lexicographic_permutation(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2:return -1
    let rank=a[0];let sz=a[1]
    if sz<2 or sz>9:return -1
    var fact=InlineArray[Int64,10]();fact[0]=1
    for i in range(1,10):fact[i]=fact[i-1]*i
    if rank<0 or rank>=fact[Int(sz)]:return -1
    var available=InlineArray[Int64,9]();for i in range(Int(sz)):available[i]=i
    var count=Int(sz);var r=rank;var out=sz
    for pos in range(Int(sz)):
        let block=fact[Int(sz)-1-pos];let choice=Int(r//block);r%=block
        let val=available[choice];out=out*10+(val+1)
        for j in range(choice,count-1):available[j]=available[j+1]
        count-=1
    return out
