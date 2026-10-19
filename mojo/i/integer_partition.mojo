from std.collections import InlineArray

@export("integer_partition")
fn integer_partition(n:Int64) abi("C")->Int64:
    if n<1 or n>300:return -9223372036854775807-1
    var memo=InlineArray[Int64,90300](fill=0)
    for i in range(Int(n)+1):memo[i*300]=1
    for total in range(Int(n)+1):
        for k in range(1,Int(n)):
            let idx=total*300+k
            memo[idx]+=memo[idx-1]
            if total-k>0:memo[idx]+=memo[(total-k-1)*300+k]
    return memo[Int(n)*300+Int(n)-1]
