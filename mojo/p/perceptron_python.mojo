from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("perceptron_python")
fn perceptron_python(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n<9 or n>62:return -1
    for i in range(Int(n)):if not is_finite(v[i]):return -1
    let rate=v[0];let epochs=Int(v[1]);let samples=Int(v[2]);let features=Int(v[3])
    if (rate!=0.25 and rate!=0.5 and rate!=0.75 and rate!=1.0) or v[1]!=Float64(epochs) or epochs<1 or epochs>12 or v[2]!=Float64(samples) or samples<2 or samples>8 or v[3]!=Float64(features) or features<1 or features>4:return -1
    let labelpos=4+samples*features;let qpos=labelpos+samples;if Int(n)<=qpos:return -1
    let queries=Int(v[qpos]);if v[qpos]!=Float64(queries) or queries<1 or queries>4 or Int(n)!=qpos+1+queries*features or n>61:return -1
    var x=InlineArray[Float64,32](fill=0.0);var y=InlineArray[Float64,8](fill=0.0);var query=InlineArray[Float64,16](fill=0.0)
    for i in range(samples*features):let z=v[4+i];if z < -2.0 or z>2.0 or z!=Float64(Int(z)):return -1;x[i]=z
    for i in range(samples):let z=v[labelpos+i];if z!=-1.0 and z!=1.0:return -1;y[i]=z
    for i in range(queries*features):let z=v[qpos+1+i];if z < -2.0 or z>2.0 or z!=Float64(Int(z)):return -1;query[i]=z
    var w=InlineArray[Float64,5](-1.0,0.8444218515250481,0.7579544029403025,0.420571580830845,0.25891675029296335);var ran=0
    for ep in range(epochs):
        var mistakes=False
        for row in range(samples):
            var score=-w[0]
            for j in range(features):score+=w[j+1]*x[row*features+j]
            let pred=1 if score>=0.0 else -1
            if Float64(pred)!=y[row]:
                mistakes=True;let scale=rate*(y[row]-Float64(pred));w[0]+=scale*(-1.0)
                for j in range(features):w[j+1]+=scale*x[row*features+j]
        ran=ep+1
        if not mistakes:break
    let size=2+(features+1)+1+queries
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(size):return -2
    var p=0;o[p]=Float64(ran);p+=1;o[p]=Float64(features+1);p+=1
    for j in range(features+1):o[p]=w[j];p+=1
    o[p]=Float64(queries);p+=1
    for row in range(queries):
        var score=-w[0]
        for j in range(features):score+=w[j+1]*query[row*features+j]
        o[p]=1.0 if score>=0.0 else -1.0;p+=1
    return Int64(p)
