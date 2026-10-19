from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn wp_write(v:Int,inout bytes:InlineArray[UInt8,1025],inout p:Int):
    var x=v;var digits=InlineArray[UInt8,4]();var dc=0
    if x==0:digits[0]=48;dc=1
    while x>0:digits[dc]=UInt8(48+x%10);dc+=1;x/=10
    while dc>0:dc-=1;bytes[p]=digits[dc];p+=1
@export("word_patterns")
fn word_patterns(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n<1 or n>257 or a==UnsafePointer[Int64,ImmutAnyOrigin]() or a[0]<0 or a[0]>256 or n!=c_size_t(a[0]+1):return -1
    let count=Int(a[0]);var seen=InlineArray[Int32,128]();for i in range(128):seen[i]= -1
    var staged=InlineArray[UInt8,1025]();var p=0;var next=0
    for i in range(count):
        let c=a[i+1]
        if c<0 or c>127:return -1
        var canonical=c
        if c>=97 and c<=122:canonical=c-32
        let key=Int(canonical)
        if i>0:staged[p]=46;p+=1
        if seen[key]<0:seen[key]=Int32(next);next+=1
        wp_write(Int(seen[key]),staged,p)
    let required=p+1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(required):return -2
    for i in range(p):o[i]=staged[i]
    o[p]=0
    return Int64(p)
