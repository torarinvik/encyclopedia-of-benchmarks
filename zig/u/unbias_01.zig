export fn unbias_01(input: [*]const i64, length: usize) i64 {
    if (length < 1 or length > 257) return -1;
    const n=input[0]; if(n<0 or n>256 or length!=@as(usize,@intCast(n))+1)return -1;
    for(0..@as(usize,@intCast(n)))|i|if(input[i+1]!=0 and input[i+1]!=1)return -1;
    var i:usize=0;while(i+1<@as(usize,@intCast(n))):(i+=2){if(input[i+1]!=input[i+2])return input[i+1];}
    return -1;
}
