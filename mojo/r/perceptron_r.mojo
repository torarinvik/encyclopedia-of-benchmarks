from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.math import isfinite,trunc
fn pr_integer(x:Float64,lo:Int,hi:Int)->Bool:return isfinite(x) and x>=Float64(lo) and x<=Float64(hi) and x==trunc(x)
fn pr_rate(x:Float64)->Bool:return x==0.25 or x==0.5 or x==0.75 or x==1.0
fn pr_score(w:InlineArray[Float64,5],x:InlineArray[Float64,5],len:Int)->Float64:
    var sum:Float64=0.0
    for i in range(len):sum+=w[i]*x[i]
    return sum
@export("perceptron_r")
fn perceptron_r(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n<8 or n>62:return -1
    for i in range(Int(n)):if not isfinite(v[i]):return -1
    if not pr_rate(v[0]) or not pr_integer(v[1],1,12) or not pr_integer(v[2],2,8) or not pr_integer(v[3],1,4):return -1
    let epochs=Int(v[1]);let samples=Int(v[2]);let features=Int(v[3]);let labels_at=4+samples*features;let qidx=labels_at+samples
    if n<=c_size_t(qidx) or not pr_integer(v[qidx],1,4):return -1
    let queries=Int(v[qidx]);if n!=c_size_t(qidx+1+queries*features) or n>61:return -1
    var x=InlineArray[Float64,32](fill=0.0);var labels=InlineArray[Float64,8](fill=0.0);var query=InlineArray[Float64,16](fill=0.0)
    for i in range(samples*features):if not pr_integer(v[4+i],-2,2):return -1;x[i]=v[4+i]
    for i in range(samples):if not pr_integer(v[labels_at+i],-2,2):return -1;labels[i]=v[labels_at+i]
    for i in range(queries*features):if not pr_integer(v[qidx+1+i],-2,2):return -1;query[i]=v[qidx+1+i]
    var classes=InlineArray[Float64,3](fill=0.0);var nc=0
    for value in range(-2,3):
        var found=False
        for i in range(samples):if labels[i]==Float64(value):found=True
        if found and nc<3:classes[nc]=Float64(value);nc+=1
    if nc<2 or nc>3:return -1
    var train=InlineArray[Float64,40](fill=0.0);var test=InlineArray[Float64,20](fill=0.0)
    for row in range(samples):train[row*(features+1)]=1.0;for j in range(features):train[row*(features+1)+j+1]=x[row*features+j]
    for row in range(queries):test[row*(features+1)]=1.0;for j in range(features):test[row*(features+1)+j+1]=query[row*features+j]
    var weights=InlineArray[Float64,15](fill=0.0)
    if nc==2:
        for epoch in range(epochs):
            for row in range(samples):
                let label=if labels[row]==classes[0]: -1.0 else:1.0;var w=InlineArray[Float64,5](fill=0.0);var a=InlineArray[Float64,5](fill=0.0)
                for j in range(features+1):w[j]=weights[j];a[j]=train[row*(features+1)+j]
                let value=pr_score(w,a,features+1)
                if label*value<=0:
                    for j in range(features+1):weights[j]+=v[0]*label*train[row*(features+1)+j]
    else:
        for epoch in range(epochs):
            for row in range(samples):
                var scores=InlineArray[Float64,3](fill=0.0);var target=0
                for c in range(nc):
                    for j in range(features+1):scores[c]+=weights[c*(features+1)+j]*train[row*(features+1)+j]
                    if c>0 and scores[c]>scores[target]:target=c
                target=0
                while target<nc and labels[row]!=classes[target]:target+=1
                var predicted=0
                for c in range(1,nc):if scores[c]>scores[predicted]:predicted=c
                if predicted!=target:
                    for j in range(features+1):let update=v[0]*train[row*(features+1)+j];weights[target*(features+1)+j]+=update;weights[predicted*(features+1)+j]-=update
    var staged=InlineArray[Float64,25](fill=0.0);var pos=0;staged[pos]=Float64(nc);pos+=1
    for c in range(nc):staged[pos]=classes[c];pos+=1
    let params=if nc==2:features+1 else:nc*(features+1);staged[pos]=Float64(params);pos+=1
    for i in range(params):staged[pos]=weights[i];pos+=1
    staged[pos]=Float64(queries);pos+=1
    for row in range(queries):
        var scores=InlineArray[Float64,3](fill=0.0);var predicted=0
        if nc==2:
            for j in range(features+1):scores[0]+=weights[j]*test[row*(features+1)+j]
            predicted=if scores[0]>=0:1 else:0
        else:
            for c in range(nc):
                for j in range(features+1):scores[c]+=weights[c*(features+1)+j]*test[row*(features+1)+j]
                if c>0 and scores[c]>scores[predicted]:predicted=c
        staged[pos]=classes[predicted];pos+=1
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(pos):return -2
    for i in range(pos):o[i]=staged[i]
    return Int64(pos)
