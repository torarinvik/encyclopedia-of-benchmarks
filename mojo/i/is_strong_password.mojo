from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("is_strong_password")
fn is_strong_password(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>258:return -1
    let minimum=input[0];let n=input[1]
    if minimum<0 or minimum>256 or n<0 or n>256 or length!=c_size_t(n+2):return -1
    var upper=False;var lower=False;var digit=False;var punctuation=False
    for i in range(Int(n)):
        let c=input[i+2]
        if c<0 or c>127:return -1
        if c>=65 and c<=90:upper=True
        if c>=97 and c<=122:lower=True
        if c>=48 and c<=57:digit=True
        if (c>=33 and c<=47) or (c>=58 and c<=64) or (c>=91 and c<=96) or (c>=123 and c<=126):punctuation=True
    return 1 if n>=minimum and upper and lower and digit and punctuation else 0
