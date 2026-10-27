const max_n: usize=16;
const max_input: usize=17;
const sample_counts=[_]usize{0,0,0,1,1,1,2,2,2,3,3,4,4,4,5,5,5};

fn put64(out:[*]u8,value:i64)void{const bits:u64=@bitCast(value);for(0..8)|j|out[j]=@truncate(bits>>@intCast(8*j));}

export fn secretary_1e_threshold(input_opt:?[*]const i64,length:usize,output_opt:?[*]u8,capacity:usize)i64{
    if(input_opt==null or length<4 or length>max_input)return -1;
    const input=input_opt.?;const n64=input[0];
    if(n64<3 or n64>16 or length!=@as(usize,@intCast(n64))+1)return -1;
    const n:usize=@intCast(n64);var seen:[max_n+1]bool=@splat(false);
    for(0..n)|i|{const rank=input[i+1];if(rank<1 or rank>n64)return -1;const r:usize=@intCast(rank);if(seen[r])return -1;seen[r]=true;}
    const observed=sample_counts[n];var threshold=input[1];for(1..observed)|i|{if(input[i+1]>threshold)threshold=input[i+1];}
    var selected:i64=-1;for(observed..n)|i|{if(input[i+1]>threshold){selected=@intCast(i);break;}}
    if(output_opt==null or capacity<8)return -2;var staged:[8]u8=@splat(0);put64(&staged,selected);const output=output_opt.?;for(0..8)|i|output[i]=staged[i];return 8;
}
