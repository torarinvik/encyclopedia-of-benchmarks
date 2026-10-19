from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn rho_gcd(a0:Int64,b0:Int64)->Int64:
    var a=a0;var b=b0
    while a!=0:let r=b%a;b=a;a=r
    return b
fn rho_pow(base0:Int64,power0:Int64,m:Int64)->Int64:
    var b=base0%m;var e=power0;var r=Int64(1)
    while e>0:
        if e%2!=0:r=(r*b)%m
        b=(b*b)%m;e//=2
    return r
fn rho_prime(n:Int64)->Bool:
    if n<=4:return n==2 or n==3
    var bases=InlineArray[Int64,4](2,3,5,7)
    var d=n-1;var s=Int64(0)
    while d%2==0:d//=2;s+=1
    for i in range(4):
        let a=bases[i]
        if n==a:continue
        var x=rho_pow(a,d,n)
        if x==1 or x==n-1:continue
        var passed=False
        for _ in range(1,Int(s)):
            x=(x*x)%n
            if x==n-1:passed=True;break
        if not passed:return False
    return True
fn rho_next(x:Int64,c:Int64,n:Int64)->Int64:return (x*x+c)%n
fn rho_brent(n:Int64,x0:Int64,c:Int64)->Int64:
    var x=x0;var x_start=Int64(0);var y=Int64(0);var rem=Int64(1);var g=Int64(1);var r=Int64(1)
    while g==1:
        y=x
        for _ in range(1,Int(r)):x=rho_next(x,c,n)
        var big=Int64(0)
        while big<r and g==1:
            x_start=x;var small=Int64(0)
            let bound=min(Int64(32),r-big)
            while small<bound:
                small+=1;x=rho_next(x,c,n)
                let diff=if x>=y:x-y else:y-x
                rem=(rem*diff)%n
            g=rho_gcd(rem,n);big+=32
        r*=2
        if r>262144:break
    if g==n:
        while g==1:
            x_start=rho_next(x_start,c,n)
            let diff=if x_start>=y:x_start-y else:y-x_start
            g=rho_gcd(diff,n)
    return g

@export("pollard_rho_rust")
fn pollard_rho_rust(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=3:return -1
    let number=v[0];var state=v[1];let restarts=v[2]
    if number<2 or number>1000000000 or state<0 or state>=4294967296 or restarts<1 or restarts>16:return -1
    if rho_prime(number):return number
    for _ in range(Int(restarts)):
        state=(1103515245*state+12345)%4294967296;let xh=state
        state=(1103515245*state+12345)%4294967296;let xl=state
        let x0=((xh%(number-3))*(4294967296%(number-3))+xl%(number-3))%(number-3)+2
        state=(1103515245*state+12345)%4294967296;let ch=state
        state=(1103515245*state+12345)%4294967296;let cl=state
        let c=((ch%(number-2))*(4294967296%(number-2))+cl%(number-2))%(number-2)+1
        let factor=rho_brent(number,x0,c)
        if factor!=1 and factor!=number:return factor
    return 0
