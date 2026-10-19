fn mr_pow(mut base:Int64,mut exponent:Int64,modulus:Int64)->Int64:
    var result:Int64=1;base%=modulus
    while exponent>0:
        if exponent%2!=0:result=(result*base)%modulus
        base=(base*base)%modulus;exponent/=2
    return result
fn mr_pass(n:Int64,base:Int64,d:Int64,s:Int64)->Bool:
    var x=mr_pow(base,d,n)
    if x==1 or x==n-1:return True
    for _ in range(1,Int(s)):
        x=(x*x)%n
        if x==n-1:return True
    return False
@export("miller_rabin")
fn miller_rabin(n:Int64) abi("C")->Int64:
    if n<2:return 0
    if n>2147483647:return -1
    var bases=InlineArray[Int64,4](2,3,5,7)
    for i in range(4):
        if n==bases[i]:return 1
        if n%bases[i]==0:return 0
    var d=n-1;var s:Int64=0
    while d%2==0:d/=2;s+=1
    for i in range(4):if not mr_pass(n,bases[i],d,s):return 0
    return 1
