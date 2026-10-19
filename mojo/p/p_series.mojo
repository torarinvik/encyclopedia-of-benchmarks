from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn ps_power(term:Int,power:Int)->UInt64:
    var x:UInt64=1
    for _ in range(power):x*=UInt64(term)
    return x
fn ps_width(mut x:UInt64)->Int:
    var w=1
    while x>=10:x/=10;w+=1
    return w
fn ps_append(o:UnsafePointer[UInt8,MutAnyOrigin],mut p:Int,x0:UInt64):
    var x=x0;var digits=InlineArray[UInt8,20](fill=0);var count=0
    while True:digits[count]=UInt8(x%10);count+=1;x/=10;if x==0:break
    while count>0:count-=1;o[p]=UInt8(48)+digits[count];p+=1
@export("p_series")
fn p_series(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2:return -1
    let nth=Int(v[0]);let power=Int(v[1]);if nth < -256 or nth>256 or power<0 or power>7:return -1
    if nth<=0:return 0
    var need=2
    for term in range(2,nth+1):need+=5+ps_width(ps_power(term,power))
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(need):return -2
    var p=0;o[p]=49;p+=1;o[p]=10;p+=1
    for term in range(2,nth+1):o[p]=49;p+=1;o[p]=32;p+=1;o[p]=47;p+=1;o[p]=32;p+=1;ps_append(o,mut p,ps_power(term,power));o[p]=10;p+=1
    return Int64(p)
