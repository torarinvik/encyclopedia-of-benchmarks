fn stf_triangular_mod(n:Int64)->Int64:
    var left=n;var right=n+1
    if left%2==0:left//=2
    else:right//=2
    return (left%998244353)*(right%998244353)%998244353

fn stf_summatory_phi(value:Int64,total_n:Int64,
    inout prefix:InlineArray[Int64,100001],
    inout memo:InlineArray[Int64,10002],
    inout visited:InlineArray[Bool,10002])->Int64:
    if value<=100000:return prefix[Int(value)]
    let cache_index=Int(total_n//value)
    if visited[cache_index]:return memo[cache_index]
    var answer=stf_triangular_mod(value)
    var left:Int64=2
    while left<=value:
        let quotient=value//left
        let right=value//quotient
        let block_size=right-left+1
        let sub_sum=stf_summatory_phi(quotient,total_n,prefix,memo,visited)
        let contribution=(block_size%998244353)*sub_sum%998244353
        answer=(answer-contribution+998244353)%998244353
        left=right+1
    visited[cache_index]=True
    memo[cache_index]=answer
    return answer

@export("sum_of_totient_function")
fn sum_of_totient_function(n:Int64) abi("C")->Int64:
    if n<1 or n>1000000000:return -1
    var prefix=InlineArray[Int64,100001]()
    for value in range(0,100001):prefix[value]=Int64(value)
    let sieve_limit=Int(min(n,Int64(100000)))
    for prime in range(2,sieve_limit+1):
        if prefix[prime]!=Int64(prime):continue
        for multiple in range(prime,sieve_limit+1,prime):
            prefix[multiple]-=prefix[multiple]//Int64(prime)
    var running:Int64=0
    for value in range(1,sieve_limit+1):
        running=(running+prefix[value])%998244353
        prefix[value]=running
    if n<=100000:return prefix[Int(n)]
    var memo=InlineArray[Int64,10002]()
    var visited=InlineArray[Bool,10002]()
    return stf_summatory_phi(n,n,prefix,memo,visited)
