from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn solution42_is_triangular(score:Int64)->Bool:
    for n in range(1,101):if score==Int64(n*(n+1)//2):return True
    return False

@export("solution42")
fn solution42(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if length>16384:return -1
    if length==0:return 0
    if input==UnsafePointer[Int64,ImmutAnyOrigin]():return -1
    for i in range(Int(length)):if input[i]<0 or input[i]>127:return -1
    var first_line=0
    while first_line<Int(length) and input[first_line]!=10 and input[first_line]!=13:first_line+=1
    var total=Int64(0);var token_start=0
    for position in range(first_line+1):
        if position==first_line or input[position]==44:
            var start=token_start;var end=position
            while start<end and input[start]==34:start+=1
            while end>start and input[end-1]==34:end-=1
            var score=Int64(0)
            for i in range(start,end):score+=input[i]-64
            if solution42_is_triangular(score):total+=1
            token_start=position+1
    return total
