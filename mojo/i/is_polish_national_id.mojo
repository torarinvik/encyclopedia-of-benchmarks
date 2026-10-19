from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("is_polish_national_id")
fn is_polish_national_id(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=11:return -1
    var number:Int64=0
    for i in range(11):
        if input[i]<48 or input[i]>57:return -1
        number=number*10+input[i]-48
    if number<10100000 or number>99923199999:return 0
    let month=(input[2]-48)*10+input[3]-48
    let valid=(month>=1 and month<=12) or (month>=21 and month<=32) or (month>=41 and month<=52) or (month>=61 and month<=72) or (month>=81 and month<=92)
    if not valid:return 0
    let day=(input[4]-48)*10+input[5]-48
    if day<1 or day>31:return 0
    var subtotal:Int64=0
    for i in range(10):
        let weight=Int64(1 if i%4==0 else 3 if i%4==1 else 7 if i%4==2 else 9)
        subtotal+=((input[i]-48)*weight)%10
    return 1 if 10-subtotal%10==number%10 else 0
