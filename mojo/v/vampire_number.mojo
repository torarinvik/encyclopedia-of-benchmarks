@export("vampire_number")
fn vampire_number(a:UInt64,b:UInt64) abi("C")->Int64:
    if a<1 or a>9999 or b<1 or b>9999:return -1
    var x=a;var y=b;var lx=0;var ly=0
    while x>0:lx+=1;x/=10
    while y>0:ly+=1;y/=10
    if lx!=ly:return 0
    var counts=InlineArray[Int,10](fill=0);var product=a*b;var left=a;var right=b
    while product>0:counts[Int(product%10)]+=1;product/=10
    while left>0:counts[Int(left%10)]-=1;left/=10
    while right>0:counts[Int(right%10)]-=1;right/=10
    for i in range(10):if counts[i]!=0:return 0
    return 1
