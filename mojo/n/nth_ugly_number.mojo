@export("nth_ugly_number")
fn nth_ugly_number(n:Int64) abi("C")->Int64:
    if n<0 or n>12690:return -1
    var seq=InlineArray[Int64,12691]();seq[0]=1
    var i2=0;var i3=0;var i5=0
    for i in range(1,Int(n)+1):
        let a=seq[i2]*2;let b=seq[i3]*3;let c=seq[i5]*5;let next=min(a,min(b,c));seq[i]=next
        if a==next:i2+=1
        if b==next:i3+=1
        if c==next:i5+=1
    return seq[Int(n)]
