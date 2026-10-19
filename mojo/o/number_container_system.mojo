from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn ncs_int(mut b:InlineArray[UInt8,128],mut pos:Int,x:Int64):
    if x<0:b[pos]=45;pos+=1
    var v=if x<0: -x else:x;var digits=InlineArray[UInt8,20](fill=UInt8(0));var k=0
    while True:digits[k]=UInt8(48+v%10);k+=1;v/=10;if v==0:break
    while k>0:k-=1;b[pos]=digits[k];pos+=1
@export("number_container_system")
fn number_container_system(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or v[0]<0 or v[0]>32 or n!=c_size_t(1+3*v[0]):return -1
    var values=InlineArray[Int64,64](fill=0);var present=InlineArray[Int64,64](fill=0);var outbuf=InlineArray[UInt8,128](fill=UInt8(0));var pos=0
    for i in range(Int(v[0])):
        let op=v[1+3*i];let a=v[2+3*i];let b=v[3+3*i]
        if op==0:
            if a<0 or a>63 or b < -100 or b>100:return -1
            values[Int(a)]=b;present[Int(a)]=1
        elif op==1:
            if a < -100 or a>100 or b!=0:return -1
            var found:Int64= -1
            for j in range(64):
                if present[j]!=0 and values[j]==a:found=Int64(j);break
            if pos>0:outbuf[pos]=44;pos+=1
            ncs_int(outbuf,pos,found)
        else:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or c_size_t(pos)>cap:return -2
    for i in range(pos):o[i]=outbuf[i]
    return Int64(pos)
