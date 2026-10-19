from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn wc_write_uint(inout b:InlineArray[UInt8,64],inout p:Int,v:Int):
    var x=v;var digits=InlineArray[UInt8,16]();var n=0
    if x==0:digits[0]=48;n=1
    while x>0:digits[n]=UInt8(48+x%10);n+=1;x/=10
    while n>0:n-=1;p+=1;b[p]=digits[n]
fn wc_write_signed(inout b:InlineArray[UInt8,64],inout p:Int,v:Int):
    if v<0:p+=1;b[p]=45;wc_write_uint(b,p,-v)
    else:wc_write_uint(b,p,v)
fn wc_round_ratio(num:Int64,den:Int64)->Int:
    let neg=num<0;let absn=if neg then -num else num
    var q=absn/den;let r=absn%den
    if 2*r>=den:q+=1
    return Int(-q if neg else q)
@export("weight_conversions")
fn weight_conversions(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2 or a[0]<0 or a[0]>5 or a[1]< -1000000 or a[1]>1000000:return -1
    let op=Int(a[0]);let amount=a[1];var b=InlineArray[UInt8,64]();var p= -1
    if op==0:wc_write_signed(b,p,Int(amount*1000))
    elif op==1:
        var q=amount/1000;if amount<0 and amount%1000!=0:q-=1
        wc_write_signed(b,p,Int(q))
    elif op==2:wc_write_signed(b,p,Int(amount*16))
    elif op==3:
        var q=amount/16;if amount<0 and amount%16!=0:q-=1
        wc_write_signed(b,p,Int(q))
    else:
        let cents=wc_round_ratio(amount*(441 if op==4 else 20000),(2 if op==4 else 441))
        let neg=cents<0;let absval=if neg then -cents else cents
        if neg:p+=1;b[p]=45
        wc_write_uint(b,p,absval/100);let frac=absval%100
        p+=1;b[p]=46
        if frac==0:p+=1;b[p]=48
        elif frac%10==0:p+=1;b[p]=UInt8(48+frac/10)
        else:p+=1;b[p]=UInt8(48+frac/10);p+=1;b[p]=UInt8(48+frac%10)
    let outlen=p+1
    if cap<c_size_t(outlen+1) or o==UnsafePointer[UInt8,MutAnyOrigin]():return -2
    for i in range(outlen):o[i]=b[i]
    o[outlen]=0
    return Int64(outlen)
