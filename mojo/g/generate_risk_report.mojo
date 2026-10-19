from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray
from std.math import abs, floor, isfinite, log, sqrt, exp

fn gr_qnorm(p:Float64)->Float64:
    let q=p-0.5
    if abs(q)<=0.425:
        let r=0.180625-q*q
        let num=((((((((2509.0809287301226727*r+33430.575583588128105)*r+67265.770927008700853)*r+45921.953931549871457)*r+13731.693765509461125)*r+1971.5909503065514427)*r+133.14166789178437745)*r+3.387132872796366608)
        let den=(((((((5226.495278852854561*r+28729.085735721942674)*r+39307.89580009271061)*r+21213.794301586595867)*r+5394.1960214247511077)*r+687.1870074920579083)*r+42.313330701600911252)*r+1.0
        return q*num/den
    let r=sqrt(-log(1.0-p))-1.6
    let num=((((((((0.00077454501427834140764*r+0.0227238449892691845833)*r+0.24178072517745061177)*r+1.27045825245236838258)*r+3.64784832476320460504)*r+5.7694972214606914055)*r+4.6303378461565452959)*r+1.42343711074968357734)
    let den=((((((((1.05075007164441684324e-9*r+0.0005475938084995344946)*r+0.0151986665636164571966)*r+0.14810397642748007459)*r+0.68976733498510000455)*r+1.6763848301838038494)*r+2.05319162663775882187)*r+1.0)
    return num/den

@export("generate_risk_report")
fn generate_risk_report(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n<24 or n>69:return -1
    for i in range(Int(n)):if not isfinite(v[i]):return -1
    let portfolio=v[0];let confidence=v[1];let horizon=v[2];let countv=v[3]
    if countv<20.0 or countv>64.0 or floor(countv)!=countv:return -1
    let count=Int(countv)
    if n!=c_size_t(4+count) or portfolio<100.0 or portfolio>1000000.0 or confidence<0.5 or confidence>0.95 or horizon<1.0 or horizon>10.0:return -1
    var vals=InlineArray[Float64,64](fill=0.0);var sum=0.0
    for i in range(count):
        let x=v[4+i];if x< -0.25 or x>0.25:return -1
        vals[i]=x;sum+=x
    let mean=sum/Float64(count);var ss=0.0
    for i in range(count):let d=vals[i]-mean;ss+=d*d
    let sd=sqrt(ss/Float64(count-1));if sd==0.0:return -1
    let tails=Int(floor((1.0-confidence)*Float64(count)));if tails<1:return -1
    for i in range(1,count):
        let x=vals[i];var pos=i
        while pos>0 and vals[pos-1]>x:vals[pos]=vals[pos-1];pos-=1
        vals[pos]=x
    var tail_sum=0.0
    for i in range(tails):tail_sum+=vals[i]
    let hs=sqrt(horizon);let z=gr_qnorm(confidence);let density=exp(-0.5*z*z)/sqrt(6.28318530717958647692);let mult=density/(1.0-confidence)
    var third=0.0;var fourth=0.0
    for i in range(count):let d=vals[i]-mean;let sq=d*d;third+=sq*d;fourth+=sq*sq
    third/=Float64(count);fourth/=Float64(count)
    var result=InlineArray[Float64,8](fill=0.0)
    result[0]= -vals[tails-1]*portfolio*hs;result[1]= -(tail_sum/Float64(tails))*portfolio*hs
    result[2]=portfolio*(z*sd-mean)*hs;result[3]=portfolio*(mult*sd-mean)*hs
    result[4]=mean;result[5]=sd;result[6]=third/(sd*sd*sd);result[7]=fourth/(sd*sd*sd*sd)-3.0
    if out==UnsafePointer[Float64,MutAnyOrigin]() or cap<8:return -2
    for i in range(8):out[i]=result[i]
    return 8
