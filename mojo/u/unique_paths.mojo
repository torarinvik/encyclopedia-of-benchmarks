@export("unique_paths")
fn unique_paths(rows: Int64, cols: Int64) abi("C") -> Int64:
    if rows<1 or rows>34 or cols<1 or cols>34:return -1
    let small=Int(min(rows,cols)); let large=Int(max(rows,cols))
    var dp=InlineArray[Int64,34](fill=1)
    for r in range(1,large):
        for c in range(1,small): dp[c]+=dp[c-1]
    return dp[small-1]
