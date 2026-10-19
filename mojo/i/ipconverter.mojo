from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

@export("ipconverter")
fn ipconverter(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,
               output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>38:return -1
    let mode=input[0];let plen=input[1]
    if (mode!=0 and mode!=1) or plen<0 or plen>35 or length!=c_size_t(plen+2):return -1
    var octets=InlineArray[Int64,4](fill=0);var pos=0
    if mode==0:
        if plen<7 or plen>15:return -1
        for oct in range(4):
            var digits=0;var value:Int64=0
            while pos<Int(plen) and input[2+pos]!=46:
                let c=input[2+pos]
                if digits==3 or c<48 or c>57:return -1
                value=value*10+c-48
                if value>255:return -1
                digits+=1;pos+=1
            if digits==0:return -1
            octets[oct]=value
            if oct<3:
                if pos>=Int(plen) or input[2+pos]!=46:return -1
                pos+=1
            elif pos!=Int(plen):return -1
    else:
        if plen!=35:return -1
        for oct in range(4):
            var value:Int64=0
            for _ in range(8):
                let c=input[2+pos];pos+=1
                if c!=48 and c!=49:return -1
                value=value*2+c-48
            octets[oct]=value
            if oct<3:
                if input[2+pos]!=46:return -1
                pos+=1
        if pos!=Int(plen):return -1
    var needed=35
    if mode==1:
        needed=3
        for i in range(4):needed+=2 if octets[i]>=100 else 1 if octets[i]>=10 else 0
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(needed):return -2
    pos=0
    for oct in range(4):
        if mode==0:
            for bit in range(7,-1,-1):
                output[pos]=UInt8(48+((octets[oct]>>UInt(bit))&1));pos+=1
        else:
            var value=octets[oct]
            if value>=100:output[pos]=UInt8(48+value//100);pos+=1;value%=100
            if value>=10:output[pos]=UInt8(48+value//10);pos+=1;value%=10
            output[pos]=UInt8(48+value);pos+=1
        if oct<3:output[pos]=46;pos+=1
    return Int64(pos)
