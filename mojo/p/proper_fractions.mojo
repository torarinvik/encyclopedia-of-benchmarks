from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn pf_gcd(a_in:Int64,b_in:Int64)->Int64:
    var a=a_in;var b=b_in
    while b!=0:let r=a%b;a=b;b=r
    return a
fn pf_width(value_in:Int64)->Int:
    var value=value_in;var width=1
    while value>=10:value//=10;width+=1
    return width
fn pf_append(out:UnsafePointer[UInt8,MutAnyOrigin],pos_in:Int,value_in:Int64)->Int:
    var digits=InlineArray[UInt8,20](fill=0);var value=value_in;var n=0
    while True:digits[n]=UInt8(value%10);n+=1;value//=10;if value==0:break
    var pos=pos_in
    while n>0:n-=1;out[pos]=48+digits[n];pos+=1
    return pos
@export("proper_fractions")
fn proper_fractions(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if values==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=1:return -1
    let d=values[0]
    if d<0 or d>256:return -1
    if d<=1:return 0
    var needed=0
    for n in range(1,Int(d)):
        if pf_gcd(Int64(n),d)==1:needed+=pf_width(Int64(n))+pf_width(d)+2
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(needed):return -2
    var pos=0
    for n in range(1,Int(d)):
        if pf_gcd(Int64(n),d)==1:
            pos=pf_append(output,pos,Int64(n));output[pos]=47;pos+=1;pos=pf_append(output,pos,d);output[pos]=10;pos+=1
    return Int64(pos)
