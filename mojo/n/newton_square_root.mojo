@export("newton_square_root")
fn newton_square_root(n:Int64) abi("C")->Int64:
    if n<0 or n>4611686018427387903:return -1
    if n==0:return 0
    var power:Int64=1;var exponent=0
    while power<n:power*=2;exponent+=1
    var root:Int64=1 << ((exponent+1)//2)
    while True:
        let square=root*root
        if square<=n and n<=square+2*root:return root
        root=(root+n/root)/2
