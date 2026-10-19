fn mif_pow(mut b:Int64,mut e:Int64,m:Int64)->Int64:
    b%=m;var r:Int64=1
    while e>0:
        if e%2!=0:r=(r*b)%m
        b=(b*b)%m;e>>=1
    return r
fn mif_prime(n:Int64)->Bool:
    if n<=1:return False
    var d:Int64=2
    while d*d<=n:
        if n%d==0:return False
        d+=1
    return True
@export("modular_inverse_fermat_little_theorem")
fn modular_inverse_fermat_little_theorem(a:Int64,m:Int64) abi("C")->Int64:
    if a<1 or a>1000000 or m<2 or m>1000000 or a%m==0 or not mif_prime(m):return -1
    return mif_pow(a,m-2,m)
