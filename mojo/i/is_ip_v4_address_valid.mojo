from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("is_ip_v4_address_valid")
fn is_ip_v4_address_valid(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if (input==UnsafePointer[Int64,ImmutAnyOrigin]() and length!=0) or length>32:return -1
    for i in range(Int(length)):
        if input[i]<0 or input[i]>127:return -1
    var segments=0;var digits=0;var octet:Int64=0;var leading=False
    for i in range(Int(length)):
        let c=input[i]
        if c==46:
            if digits==0 or octet>255 or segments>=3:return 0
            segments+=1;digits=0;octet=0;leading=False
        else:
            if c<48 or c>57:return 0
            if digits==0:leading=c==48
            elif leading:return 0
            octet=octet*10+c-48
            if octet>255:return 0
            digits+=1
            if digits>3:return 0
    return 1 if segments==3 and digits>0 and octet<=255 else 0
