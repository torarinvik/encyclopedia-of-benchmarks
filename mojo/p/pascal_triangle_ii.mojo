@export("pascal_triangle_ii")
fn pascal_triangle_ii(row:Int64) abi("C")->Int64:
    if row<0 or row>30:return -9223372036854775808
    var a=InlineArray[Int64,31](fill=0);a[0]=1
    for i in range(1,Int(row)+1):a[i]=1;for j in range(i-1,0,-1):a[j]=a[j-1]+a[j]
    var h:Int64=0
    for j in range(Int(row)+1):h=(h*31+a[j])%1000000007
    return h
