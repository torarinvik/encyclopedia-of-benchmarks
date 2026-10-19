@export("pell_number")
fn pell_number(n:Int64) abi("C")->Int64:
    if n<0 or n>50:return -1
    if n==0:return 0
    var prev:Int64=0;var cur:Int64=1
    for _ in range(2,Int(n)+1):let next=2*cur+prev;prev=cur;cur=next
    return cur
