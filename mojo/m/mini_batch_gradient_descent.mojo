from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import isfinite
@export("mini_batch_gradient_descent")
fn mini_batch_gradient_descent(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n<5 or n>101:return -1
    for i in range(Int(n)):if not isfinite(v[i]):return -1
    if v[0]<1.0 or v[0]>8.0 or v[1]<1.0 or v[1]>3.0 or Float64(Int(v[0]))!=v[0] or Float64(Int(v[1]))!=v[1]:return -1
    let samples=Int(v[0]);let features=Int(v[1])
    if v[2]<1.0 or v[2]>Float64(samples) or v[3]<0.0 or v[3]>8.0 or Float64(Int(v[2]))!=v[2] or Float64(Int(v[3]))!=v[3] or v[4]<0.0 or v[4]>0.25:return -1
    let batch=Int(v[2]);let epochs=Int(v[3]);let ms=5;let me=ms+samples*features;let ye=me+samples
    if Int(n)!=ye+epochs*samples:return -1
    var matrix=InlineArray[Float64,24](fill=0.0);var targets=InlineArray[Float64,8](fill=0.0)
    for i in range(samples*features):if v[ms+i] < -10.0 or v[ms+i]>10.0:return -1;matrix[i]=v[ms+i]
    for i in range(samples):if v[me+i] < -100.0 or v[me+i]>100.0:return -1;targets[i]=v[me+i]
    var orders=InlineArray[Int64,64](fill=0)
    for e in range(epochs):
        var seen=InlineArray[Int64,8](fill=0)
        for p in range(samples):
            let x=v[ye+e*samples+p]
            if x<0.0 or x>=Float64(samples) or Float64(Int(x))!=x:return -1
            let idx=Int(x);if seen[idx]!=0:return -1;seen[idx]=1;orders[e*8+p]=Int64(idx)
    var weights=InlineArray[Float64,3](fill=0.0);var bias=0.0;let lr=v[4]
    for epoch in range(epochs):
        var start=0
        while start<samples:
            let batchlen=min(samples-start,batch);var errors=InlineArray[Float64,8](fill=0.0)
            for pos in range(batchlen):
                let sample=Int(orders[epoch*8+start+pos]);var pred=0.0
                for f in range(features):
                    let product=matrix[sample*features+f]*weights[f]
                    if not isfinite(product):return -1
                    pred+=product
                    if not isfinite(pred):return -1
                pred+=bias
                if not isfinite(pred):return -1
                errors[pos]=pred-targets[sample]
                if not isfinite(errors[pos]):return -1
            for f in range(features):
                var grad=0.0
                for pos in range(batchlen):
                    let sample=Int(orders[epoch*8+start+pos]);let product=matrix[sample*features+f]*errors[pos]
                    if not isfinite(product):return -1
                    grad+=product
                    if not isfinite(grad):return -1
                let update=(lr*grad)/Float64(batchlen)
                if not isfinite(update):return -1
                weights[f]-=update
                if not isfinite(weights[f]):return -1
            var esum=0.0
            for pos in range(batchlen):esum+=errors[pos];if not isfinite(esum):return -1
            let mean=esum/Float64(batchlen);if not isfinite(mean):return -1
            let bu=lr*mean;if not isfinite(bu):return -1
            bias-=bu;if not isfinite(bias):return -1
            start+=batchlen
    if out==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(features+1):return -2
    for f in range(features):out[f]=weights[f]
    out[features]=bias
    return Int64(features+1)
