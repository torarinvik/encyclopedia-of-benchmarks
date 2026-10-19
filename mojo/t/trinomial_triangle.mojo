from std.memory import ImmutAnyOrigin, UnsafePointer
@export("trinomial_triangle")
fn trinomial_triangle(a:UnsafePointer[Int64,ImmutAnyOrigin],n:UInt)->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2:return -1
    let row=a[0];let col=a[1]
    if row<0 or row>10 or col< -10 or col>10:return -1
    var prev=InlineArray[Int64,23]();prev[11]=1
    for r in range(1,Int(row)+1):
        var next=InlineArray[Int64,23]()
        for k in range(-r,r+1):next[k+11]=prev[k-1+11]+prev[k+11]+prev[k+1+11]
        prev=next
    return prev[Int(col)+11]
