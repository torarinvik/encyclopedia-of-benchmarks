from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn ip_whitespace(x:Int64)->Bool:
    return x==9 or x==10 or x==11 or x==12 or x==13 or x==32
fn ip_tail(phone:UnsafePointer[Int64,ImmutAnyOrigin],end:Int,pos:Int)->Bool:
    if pos>end or end-pos!=10 or phone[pos]<55 or phone[pos]>57:return False
    for i in range(1,10):
        if phone[pos+i]<48 or phone[pos+i]>57:return False
    return True

@export("indian_phone_validator")
fn indian_phone_validator(phone:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if phone==UnsafePointer[Int64,ImmutAnyOrigin]() or length==0 or length>18:return -1
    for i in range(Int(length)):
        if phone[i]<0 or phone[i]>127:return -1
    var end=Int(length)
    if phone[end-1]==10:end-=1
    var prefix=0
    if end>=3 and phone[0]==43 and phone[1]==57 and phone[2]==49:
        prefix=3
        if prefix<end and (phone[prefix]==45 or ip_whitespace(phone[prefix])):prefix+=1
    for zero in range(2):
        var after=prefix
        if zero==1:
            if after>=end or phone[after]!=48:continue
            after+=1
        for country in range(2):
            var pos=after
            if country==1:
                if pos+2>end or phone[pos]!=57 or phone[pos+1]!=49:continue
                pos+=2
            if ip_tail(phone,end,pos):return 1
    return 0
