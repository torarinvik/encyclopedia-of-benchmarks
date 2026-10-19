from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("is_srilankan_phone_number")
fn is_srilankan_phone_number(phone:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if phone==UnsafePointer[Int64,ImmutAnyOrigin]() or length==0 or length>15:return -1
    for i in range(Int(length)):
        if phone[i]<0 or phone[i]>127:return -1
    var prefix=0
    if phone[0]==48:
        if length>=4 and phone[1]==48 and phone[2]==57 and phone[3]==52:prefix=4
        else:prefix=1
    elif length>=2 and phone[0]==57 and phone[1]==52:prefix=2
    elif length>=3 and phone[0]==43 and phone[1]==57 and phone[2]==52:prefix=3
    else:return 0
    var cursor=prefix
    if cursor+2>Int(length) or phone[cursor]!=55:return 0
    cursor+=1;let provider=phone[cursor];cursor+=1
    if provider!=48 and provider!=49 and provider!=50 and provider!=52 and provider!=53 and provider!=54 and provider!=55 and provider!=56:return 0
    var end=Int(length)
    if phone[end-1]==10:end-=1
    let remaining=end-cursor
    if remaining==8 and (phone[cursor]==45 or phone[cursor]==32):cursor+=1
    elif remaining!=7:return 0
    for i in range(7):
        if phone[cursor+i]<48 or phone[cursor+i]>57:return 0
    return 1
