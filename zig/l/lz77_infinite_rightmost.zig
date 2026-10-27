const max_text: usize = 64;
const max_input: usize = 66;
const max_output: usize = 1536;
fn put64(out: [*]u8, at: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |i| out[at+i] = @truncate(bits >> @intCast(i*8));
}
export fn lz77_infinite_rightmost(input_opt:?[*]const i64,len:usize,output_opt:?[*]u8,capacity:usize)i64{
    if(input_opt==null||len<1||len>max_input)return -1;
    const input=input_opt.?;if(input[0]<0||input[0]>max_text)return -1;
    const n:usize=@intCast(input[0]);if(len!=n+1)return -1;
    for(0..n)|i|{if(input[i+1]<32||input[i+1]>126)return -1;}
    var staged=[_]u8{0}**max_output;var tokens:usize=0;var q:usize=0;
    while(q<n){var bl:usize=0;var bp:usize=0;var found=false;
        for(0..q)|p|{var l:usize=0;while(q+l<n and input[p+l+1]==input[q+l+1]):(l+=1){}
            if(l>bl or (l==bl and l>0 and (!found or p>bp))){bl=l;bp=p;found=true;}}
        const source_pos: i64=if(found) @intCast(bp) else 0;
        const np=q+bl;const ch:i64=if(np<n) input[np+1] else 0;const at=tokens*24;
        put64(&staged,at,source_pos);put64(&staged,at+8,@intCast(bl));put64(&staged,at+16,ch);tokens+=1;
        q=if(ch!=0)np+1 else np;
    }
    const bytes=tokens*24;const out=output_opt orelse return -2;if(capacity<bytes)return -2;
    if(bytes>0)@memcpy(out[0..bytes],staged[0..bytes]);return @intCast(bytes);
}
