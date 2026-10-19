from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray
@export("gradient_boosting_regressor")
fn gradient_boosting_regressor(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<8 or n>36:return -1.0e300
    let count=Int(v[0]);let rounds=v[1];let ratei=v[2];let query=v[3]
    if count<2 or count>16 or rounds<1 or rounds>12 or ratei<1 or ratei>1000000 or n!=c_size_t(4+2*count):return -1.0e300
    var x=InlineArray[Float64,16](fill=0.0);var y=InlineArray[Float64,16](fill=0.0);var pred=InlineArray[Float64,16](fill=0.0);var residual=InlineArray[Float64,16](fill=0.0)
    for i in range(count):
        let xi=v[4+i];let yi=v[4+count+i]
        if xi< -1000 or xi>1000 or yi< -1000000 or yi>1000000 or (i>0 and v[3+i]>=xi):return -1.0e300
        x[i]=Float64(xi);y[i]=Float64(yi)/1000.0
    if query< -1000 or query>1000:return -1.0e300
    var mean=0.0
    for i in range(count):mean+=y[i]
    mean/=Float64(count)
    for i in range(count):pred[i]=mean
    var qpred=mean;let rate=Float64(ratei)/1000000.0
    for r in range(Int(rounds)):
        var sum=0.0;for i in range(count):residual[i]=y[i]-pred[i];sum+=residual[i]
        var constant=True;for i in range(1,count):if residual[i]!=residual[0]:constant=False
        var best=1.0e300;var left=0.0;var right=0.0;var split=count
        if not constant:
            for s in range(count-1):
                let nl=s+1;let nr=count-nl;var sl=0.0;var sr=0.0
                for i in range(nl):sl+=residual[i]
                for i in range(nl,count):sr+=residual[i]
                let lm=sl/Float64(nl);let rm=sr/Float64(nr);var err=0.0
                for i in range(nl):let d=residual[i]-lm;err+=d*d
                for i in range(nl,count):let d=residual[i]-rm;err+=d*d
                if err<best:best=err;split=s;left=lm;right=rm
        if split==count:
            let leaf=sum/Float64(count)
            for i in range(count):pred[i]+=rate*leaf
            qpred+=rate*leaf
        else:
            let threshold=(x[split]+x[split+1])/2.0
            for i in range(count):pred[i]+=rate*(left if x[i]<=threshold else right)
            qpred+=rate*(left if Float64(query)<=threshold else right)
    return qpred
