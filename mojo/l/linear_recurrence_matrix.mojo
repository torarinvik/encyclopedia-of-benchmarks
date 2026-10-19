from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
comptime MODULUS=1000000007
fn rec_mul(a:InlineArray[Int64,16],b:InlineArray[Int64,16],mut o:InlineArray[Int64,16],d:Int):
    for r in range(d):
        for c in range(d):
            var value:Int64=0
            for k in range(d):value=(value+(a[r*d+k]%MODULUS)*(b[k*d+c]%MODULUS)%MODULUS)%MODULUS
            o[r*d+c]=value
@export("linear_recurrence_matrix")
fn linear_recurrence_matrix(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>24:return -1
    let dv=v[0];let nth=v[1];let include=v[2]
    if dv<1 or dv>4 or nth<0 or nth>1000000 or (include!=0 and include!=1):return -1
    let d=Int(dv);let m=d*d
    if n!=c_size_t(3+m+d) or (include==1 and nth<dv-1):return -1
    var matrix=InlineArray[Int64,16](fill=0);var row=InlineArray[Int64,4](fill=0)
    for i in range(m+d):
        let x=v[3+i]
        if x<0 or x>=MODULUS:return -1
        if i<m:matrix[i]=x
        else:row[i-m]=x
    if nth<dv-include:return row[Int(nth-include)]
    var zero=True
    for i in range(m):
        if matrix[i]!=0:zero=False
    if zero:return 0
    var result=InlineArray[Int64,16](fill=0);var work=InlineArray[Int64,16](fill=0)
    for i in range(d):result[i*d+i]=1
    var power=nth-dv+1+include
    while power>0:
        if power&1:
            rec_mul(result,matrix,work,d)
            for i in range(m):result[i]=work[i]
        power/=2;rec_mul(matrix,matrix,work,d)
        for i in range(m):matrix[i]=work[i]
    var value:Int64=0
    for i in range(d):value=(value+(row[i]%MODULUS)*(result[i*d+d-1]%MODULUS)%MODULUS)%MODULUS
    return value
