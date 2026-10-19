from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("perplexity_loss")
fn perplexity_loss(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>2179:return -1.0e300
    let batch=Int(v[0]);let time=Int(v[1]);let vocab=Int(v[2]);if batch<1 or batch>8 or time<1 or time>16 or vocab<2 or vocab>16:return -1.0e300
    let tokens=batch*time;let pc=tokens*vocab;if Int(n)!=3+tokens+pc:return -1.0e300
    let base=3+tokens
    for row in range(tokens):
        let label=v[3+row];if label<0 or label>=vocab:return -1.0e300
        var total:Int64=0
        for c in range(vocab):let p=v[base+row*vocab+c];if p<0 or p>1000000:return -1.0e300;total+=p
        if total!=1000000:return -1.0e300
    var batch_total=0.0
    for sentence in range(batch):
        var log_total=0.0
        for step in range(time):
            let row=sentence*time+step;let label=Int(v[3+row]);var prob=Float64(v[base+row*vocab+label])/1000000.0
            if prob<1e-7:prob=1e-7
            if prob>1.0:prob=1.0
            log_total+=log(prob)
        batch_total+=exp(-(log_total/Float64(time)))
    return batch_total/Float64(batch)
