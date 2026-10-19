from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn mlp_forward(row:InlineArray[Float64,3],w1:InlineArray[Float64,6],w2:InlineArray[Float64,6],mut z:InlineArray[Float64,2],mut hid:InlineArray[Float64,2],mut y:InlineArray[Float64,3]):
    for j in range(2):z[j]=row[0]*w1[j]+row[1]*w1[2+j]+row[2]*w1[4+j];hid[j]=if z[j]>0.0:z[j] else:0.0
    for k in range(3):y[k]=hid[0]*w2[k]+hid[1]*w2[3+k]
@export("multilayer_perceptron_classifier")
fn multilayer_perceptron_classifier(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n!=15:return -1
    for i in range(15):if not is_finite(v[i]):return -1
    let epochs=Int(v[0]);let lr=v[1];let gamma=v[2]
    if v[0]!=Float64(epochs) or epochs<1 or epochs>12 or (lr!=0.05 and lr!=0.1 and lr!=0.2) or (gamma!=0.5 and gamma!=0.75 and gamma!=1.0):return -1
    for i in range(8):let x=v[3+i];if x < -2.0 or x>2.0 or x*4.0!=Float64(Int(x*4.0)):return -1
    var labels=InlineArray[Int64,4](fill=0)
    for i in range(4):let x=v[11+i];if x<0.0 or x>2.0 or x!=Float64(Int(x)):return -1;labels[i]=Int64(x)
    var w1=InlineArray[Float64,6](0.30471707975443135,0.7504511958064572,-1.0399841062404955,0.9405647163912139,-1.9510351886538364,-1.302179506862318)
    var w2=InlineArray[Float64,6](0.12784040316728537,-0.3162425923435822,-0.016801157504288795,-0.85304392757358,0.8793979748628286,0.7777919354289483)
    var acc=InlineArray[Float64,12](fill=0.0);var losses=InlineArray[Float64,12](fill=0.0);var rate=lr
    for ep in range(epochs):
        for rowi in range(3):
            let row=InlineArray[Float64,3](v[3+2*rowi],v[4+2*rowi],1.0);var z=InlineArray[Float64,2](fill=0.0);var hid=InlineArray[Float64,2](fill=0.0);var y=InlineArray[Float64,3](fill=0.0);mlp_forward(row,w1,w2,mut z,mut hid,mut y)
            var delta=InlineArray[Float64,3](fill=0.0);for k in range(3):delta[k]=y[k]-(0.99 if labels[rowi]==k else 0.0)
            var dh=InlineArray[Float64,2](fill=0.0)
            for j in range(2):dh[j]=delta[0]*w2[j*3]+delta[1]*w2[j*3+1]+delta[2]*w2[j*3+2];if z[j]<=0.0:dh[j]=0.0
            for i in range(3):for j in range(2):let ix=i*2+j;w1[ix]-=rate*row[i]*dh[j]
            for j in range(2):for k in range(3):w2[j*3+k]-=rate*hid[j]*delta[k]
        let test=InlineArray[Float64,3](v[9],v[10],1.0);var zt=InlineArray[Float64,2](fill=0.0);var ht=InlineArray[Float64,2](fill=0.0);var yt=InlineArray[Float64,3](fill=0.0);mlp_forward(test,w1,w2,mut zt,mut ht,mut yt)
        var pred=0;for k in range(1,3):if yt[k]>yt[pred]:pred=k
        acc[ep]=1.0 if pred==labels[3] else 0.0;var loss=0.0
        for k in range(3):let d=yt[k]-(0.99 if labels[3]==k else 0.0);loss+=d*d
        losses[ep]=loss/2.0;rate*=gamma
    let count=2*epochs+2;if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(count):return -2
    o[0]=Float64(epochs);var sum=0.0
    for i in range(epochs):o[1+i]=acc[i];sum+=acc[i]
    for i in range(epochs):o[1+epochs+i]=losses[i]
    o[count-1]=sum/Float64(epochs);return Int64(count)
