from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn swspace(x:Int64)->Bool:return x==32 or (x>=9 and x<=13) or (x>=28 and x<=31)
fn swword(x:Int64)->Bool:return (x>=65 and x<=90) or (x>=97 and x<=122) or (x>=48 and x<=57)
@export("string_switch_case")
fn string_switch_case(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>1027:return -1
    let mode=v[0];let sep=v[1];let tl=v[2]
    if mode<0 or mode>8 or sep<0 or sep>127 or tl<0 or tl>1024 or n!=c_size_t(tl+3) or ((mode!=3 and mode!=4) and sep!=0):return -1
    for i in range(Int(tl)):if v[3+i]<0 or v[3+i]>127:return -1
    var result=InlineArray[UInt8,1024](fill=0);var used=0
    if mode<=2:
        var wordstart=True
        for i in range(Int(tl)):
            var x=v[3+i]
            if not swword(x):wordstart=True;continue
            if wordstart:
                if x>=97 and x<=122:x-=32
                wordstart=False
            elif x>=65 and x<=90:x+=32
            result[used]=UInt8(x);used+=1
        if mode==2:
            if used==0:
                let fallback=b"not valid string"
                for i in range(16):result[used]=fallback[i];used+=1
            elif result[0]>=65 and result[0]<=90:result[0]+=32
    else:
        let upper=mode==4 or mode==6 or mode==8;let delim=if mode<=4 then UInt8(sep) else (UInt8(95) if mode<=6 else UInt8(45));var group=False;var pending=False
        for i in range(Int(tl)):
            var x=v[3+i]
            if swspace(x):if group:pending=True;continue
            if not swword(x):group=False;pending=False;continue
            if pending and group:result[used]=delim;used+=1
            pending=False
            if upper and x>=97 and x<=122:x-=32
            elif not upper and x>=65 and x<=90:x+=32
            result[used]=UInt8(x);used+=1;group=True
    if cap<c_size_t(used) or (used>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    for i in range(used):o[i]=result[i]
    return Int64(used)
