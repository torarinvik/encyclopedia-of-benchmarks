@export("kolakoski_sequence")
fn kolakoski_sequence(idx:Int64) abi("C")->Int64:
    if idx<0 or idx>63:return -1
    var terms=InlineArray[Int64,64]();terms[0]=1;terms[1]=2;terms[2]=2;var read=2;var write=3;var value:Int64=1
    while write<=Int(idx):
        let run=terms[read];read+=1
        for _ in range(Int(run)):
            if write>Int(idx):break
            terms[write]=value;write+=1
        value=3-value
    return terms[Int(idx)]
