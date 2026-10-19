@export("palindrome_number")
fn palindrome_number(x:Int64) abi("C")->Int64:
    if x<0 or x>2147483647:return -1
    if x!=0 and x%10==0:return 0
    var n=x;var rev:Int64=0
    while n>rev:rev=rev*10+n%10;n/=10
    return 1 if n==rev or n==rev/10 else 0
