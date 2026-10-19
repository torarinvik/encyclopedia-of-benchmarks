@export("modular_inverse_simple")
fn modular_inverse_simple(x:Int64,y:Int64) abi("C")->Int64:
    if x<1 or x>999 or y<2 or y>1000:return -1
    var a=x;var b=y
    while b!=0:let r=a%b;a=b;b=r
    if a!=1:return -1
    var k:Int64=0;var aux:Int64=1
    while aux%x!=0:aux=y*k+1;k+=1
    return aux/x
