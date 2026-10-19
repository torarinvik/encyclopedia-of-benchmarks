from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("quadratic_residue")
fn quadratic_residue(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2:return -1
    let x=a[0];let p=a[1]
    if p<3 or p>53 or p%2==0 or x<0 or x>=p:return -1
    var valid=false
    for q in InlineArray[Int64,15](3,5,7,11,13,17,19,23,29,31,37,41,43,47,53):if p==q:valid=true
    if not valid:return -1
    if x==0:return 0
    var base=x;var exp=(p-1)/2;var result:Int64=1
    while exp>0:
        if exp%2==1:result=(result*base)%p
        base=(base*base)%p;exp=exp/2
    return 1 if result==1 else -1
