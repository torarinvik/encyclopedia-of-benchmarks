from std.memory import MutAnyOrigin, UnsafePointer
fn pp_prime(x:UInt32)->Bool:
    if x<2:return False
    var d:UInt32=2
    while d<=x/d:if x%d==0:return False;d+=1
    return True
fn pp_reverse(mut x:UInt32)->UInt32:
    var r:UInt32=0
    while x>0:r=r*10+x%10;x/=10
    return r
fn pp_put(o:UnsafePointer[UInt8,MutAnyOrigin],p:Int,x:UInt32):
    for b in range(4):o[p+b]=UInt8((x>>(8*b))&255)
@export("palindrome_prime")
fn palindrome_prime(n:Int64,o:UnsafePointer[UInt8,MutAnyOrigin],cap:UInt64) abi("C")->Int64:
    if n>16:return -1
    if n<=0:return 0
    let bytes=Int(n)*4
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<UInt64(bytes):return -2
    pp_put(o,0,2);var count=1;var candidate:UInt32=3
    while count<Int(n):if candidate==pp_reverse(candidate) and pp_prime(candidate):pp_put(o,4*count,candidate);count+=1;candidate+=2
    return Int64(bytes)
