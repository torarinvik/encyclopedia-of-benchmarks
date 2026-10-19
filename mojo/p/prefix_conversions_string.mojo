from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("prefix_conversions_string")
fn prefix_conversions_string(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2 or (v[0]!=0 and v[0]!=1) or v[1]< -1000000000000 or v[1]>1000000000000:return -1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<8192:return -2
    let mode=v[0];let value=v[1];var prefix=Int64(0)
    if value>0:
        if mode==0:
            if value>1000000000:prefix=9
            elif value>1000000:prefix=6
            elif value>1000:prefix=3
            elif value>100:prefix=2
            elif value>10:prefix=1
        else:
            if value>1073741824:prefix=30
            elif value>1048576:prefix=20
            elif value>1024:prefix=10
        if prefix!=0:
            let scale=if mode==0:pow(10.0,Float64(prefix)) else:pow(2.0,Float64(prefix))
            if Float64(value)/scale != Float64(Int64(Float64(value)/scale)):return -1
    var tmp=InlineArray[UInt8,64](fill=0);var pos=0
    var x=value
    if prefix!=0:
        let scale=if mode==0:Int64(pow(10.0,Float64(prefix))) else:Int64(pow(2.0,Float64(prefix)))
        x=value/scale
    var neg=x<0
    if neg:tmp[pos]=45;pos+=1;x=-x
    var digs=InlineArray[UInt8,24](fill=0);var d=0
    if x==0:digs[d]=48;d+=1
    while x>0:digs[d]=UInt8(48+x%10);d+=1;x//=10
    for i in range(d):tmp[pos]=digs[d-1-i];pos+=1
    if prefix!=0:
        tmp[pos]=46;tmp[pos+1]=48;pos+=2;tmp[pos]=32;pos+=1
        if mode==0:
            let label=Int(prefix)
            if label==1:tmp[pos]=100;tmp[pos+1]=101;tmp[pos+2]=99;tmp[pos+3]=97;pos+=4
            elif label==2:tmp[pos]=104;tmp[pos+1]=101;tmp[pos+2]=99;tmp[pos+3]=116;tmp[pos+4]=111;pos+=5
            elif label==3:tmp[pos]=107;tmp[pos+1]=105;tmp[pos+2]=108;tmp[pos+3]=111;pos+=4
            elif label==6:tmp[pos]=109;tmp[pos+1]=101;tmp[pos+2]=103;tmp[pos+3]=97;pos+=4
            else:tmp[pos]=103;tmp[pos+1]=105;tmp[pos+2]=103;tmp[pos+3]=97;pos+=4
        else:
            if prefix==10:tmp[pos]=107;tmp[pos+1]=105;tmp[pos+2]=108;tmp[pos+3]=111;pos+=4
            elif prefix==20:tmp[pos]=109;tmp[pos+1]=101;tmp[pos+2]=103;tmp[pos+3]=97;pos+=4
            else:tmp[pos]=103;tmp[pos+1]=105;tmp[pos+2]=103;tmp[pos+3]=97;pos+=4
    for i in range(pos):out[i]=tmp[i]
    return Int64(pos)
