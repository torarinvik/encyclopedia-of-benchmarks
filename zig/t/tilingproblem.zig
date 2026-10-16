export fn tilingproblem(input: [*]const i64, length: usize) i64 {
    if (length != 1 or input[0] < 0 or input[0] > 91) return -1;
    var previous:i64=1;var current:i64=1;var width:i64=2;while(width<=input[0]):(width+=1){const next=previous+current;previous=current;current=next;}return current;
}
