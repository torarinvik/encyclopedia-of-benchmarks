@export("happy_number")
fn happy_number(value:Int64) abi("C")->Int64:
    if value<1:return -1
    var slow=value;var fast=value
    while True:
        var a=slow;var suma:Int64=0
        while a>0:let digit=a%10;suma+=digit*digit;a//=10
        slow=suma
        for step in range(2):
            var b=fast;var s:Int64=0
            while b>0:let digit=b%10;s+=digit*digit;b//=10
            fast=s
        if fast==1:return 1
        if slow==fast:return 0
