from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn pes_qnorm(p:Float64)->Float64:
    let q=p-0.5
    if abs(q)<=0.425:
        let r=0.180625-q*q
        let a=(((((((2509.0809287301226727*r+33430.575583588128105)*r+67265.770927008700853)*r+45921.953931549871457)*r+13731.693765509461125)*r+1971.5909503065514427)*r+133.14166789178437745)*r+3.387132872796366608
        let b=(((((((5226.495278852854561*r+28729.085735721942674)*r+39307.89580009271061)*r+21213.794301586595867)*r+5394.1960214247511077)*r+687.1870074920579083)*r+42.313330701600911252)*r+1.0
        return q*a/b
    let r=sqrt(-log(1.0-p))-1.6
    let a=(((((((0.00077454501427834140764*r+0.0227238449892691845833)*r+0.24178072517745061177)*r+1.27045825245236838258)*r+3.64784832476320460504)*r+5.7694972214606914055)*r+4.6303378461565452959)*r+1.42343711074968357734
    let b=(((((((1.05075007164441684324e-9*r+0.0005475938084995344946)*r+0.0151986665636164571966)*r+0.14810397642748007459)*r+0.68976733498510000455)*r+1.6763848301838038494)*r+2.05319162663775882187)*r+1.0
    return a/b
@export("parametric_expected_shortfall")
fn parametric_expected_shortfall(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n<24 or n>69:return -1
    for i in range(Int(n)):if not is_finite(v[i]):return -1
    let count=Int(v[3]);if v[3]!=Float64(count) or count<20 or count>64 or Int(n)!=4+count or v[0]<100.0 or v[0]>1000000.0 or v[1]<0.5 or v[1]>0.95 or v[2]<1.0 or v[2]>10.0:return -1
    var sum=0.0;var r=InlineArray[Float64,64](fill=0.0)
    for i in range(count):let x=v[4+i];if x < -0.25 or x>0.25:return -1;r[i]=x;sum+=x
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<1:return -2
    let mean=sum/Float64(count);var ss=0.0
    for i in range(count):let d=r[i]-mean;ss+=d*d
    let sd=sqrt(ss/Float64(count-1));let z=pes_qnorm(v[1]);let density=exp(-z*z/2.0)/sqrt(2.0*3.141592653589793);let lambda=density/(1.0-v[1]);o[0]=v[0]*(lambda*sd-mean)*sqrt(v[2]);return 1
