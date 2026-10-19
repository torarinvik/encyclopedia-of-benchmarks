from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn email_letter(c:Int64)->Bool:return (c>=65 and c<=90) or (c>=97 and c<=122)
fn email_digit(c:Int64)->Bool:return c>=48 and c<=57
fn email_special(c:Int64)->Bool:return c==33 or c==35 or c==36 or c==37 or c==38 or c==39 or c==40 or c==41 or c==42 or c==43 or c==45 or c==46 or c==47 or c==61 or c==63 or c==94 or c==95 or c==96 or c==123 or c==124 or c==125 or c==126

@export("is_valid_email_address")
fn is_valid_email_address(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if length>320:return 0
    if length!=0 and values==UnsafePointer[Int64,ImmutAnyOrigin]():return -1
    for i in range(Int(length)):
        if values[i]<0 or values[i]>0x10ffff:return -1
    var at=Int(length)
    for i in range(Int(length)):
        if values[i]==64:
            if at!=Int(length):return 0
            at=i
    if at==Int(length):return 0
    let domain=at+1
    if at>64 or Int(length)-domain>255:return 0
    for i in range(at):
        let c=values[i]
        if not (email_letter(c) or email_digit(c) or email_special(c)):return 0
        if c==46 and (i==0 or i+1==at or values[i-1]==46):return 0
    for i in range(domain,Int(length)):
        let c=values[i]
        if not (email_letter(c) or email_digit(c) or c==46 or c==45):return 0
        if c==45 and i==domain:return 0
        if c==46 and (i==domain or i+1==Int(length) or values[i-1]==46):return 0
    return 1
