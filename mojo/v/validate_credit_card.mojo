from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("validate_credit_card")
fn validate_credit_card(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>65:return -1
    let len=v[0]
    if len<0 or len>64 or n!=c_size_t(len+1):return -1
    for i in range(Int(len)):if v[i+1]<0 or v[i+1]>127:return -1
    if len<13 or len>16:return 0
    for i in range(Int(len)):if v[i+1]<48 or v[i+1]>57:return 0
    let first=v[1]-48;let second=v[2]-48
    if not (first==4 or first==5 or first==6 or (first==3 and (second==4 or second==5 or second==7))):return 0
    var total=0
    for i in range(Int(len)):
        var digit=v[i+1]-48
        if i%2==0:
            digit*=2
            if digit>9:digit-=9
        total+=Int(digit)
    return 1 if total%10==0 else 0
