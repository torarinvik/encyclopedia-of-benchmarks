fn sieve_flag(n:Int64)->Bool:
    if n<2:return True
    var d:Int64=2
    while d<=n/d:
        if n%d==0:return False
        d+=1
    return True
@export("sphenic_number")
fn sphenic_number(value:Int64) abi("C")->Int64:
    if value<0 or value>1000:return -1
    var first=InlineArray[Int64,3](fill=0);var count=0;var d:Int64=1
    while d<=value:
        if value%d==0 and count<9:
            if count<3:first[count]=d
            count+=1
        d+=1
    return 1 if count==8 and sieve_flag(first[0]) and sieve_flag(first[1]) and sieve_flag(first[2]) else 0
