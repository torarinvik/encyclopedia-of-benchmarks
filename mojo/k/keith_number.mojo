@export("keith_number")
fn keith_number(x:Int64) abi("C")->Int64:
    if x<10 or x>999999:return -1
    var a=InlineArray[Int64,6]();var rev=InlineArray[Int64,6]();var v=x;var n=0
    while v>0:rev[n]=v%10;n+=1;v//=10
    for i in range(n):a[i]=rev[n-1-i]
    var oldest=0
    while True:
        var s:Int64=0
        for i in range(n):s+=a[(oldest+i)%n]
        if s>=x:return 1 if s==x else 0
        a[oldest]=s;oldest=(oldest+1)%n
    return 0
