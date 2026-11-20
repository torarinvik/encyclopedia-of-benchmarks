const QMAX: usize = 40;
fn put(output: [*]u8, at: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| output[at+b] = @truncate(bits >> @intCast(8*b));
}

pub export fn two_left_hashing_operation_trace(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 5 or length > 162) return -1;
    const qv=input[0];if(qv<1 or qv>QMAX)return -1;
    const q:usize=@intCast(qv);if(length!=1+4*q)return -1;
    for(0..q)|i|{
        const op=input[1+4*i];const key=input[2+4*i];const left=input[3+4*i];const right=input[4+4*i];
        if(op<0 or op>2 or key<0 or key>63 or left<0 or left>7 or right<0 or right>7)return -1;
        for(0..i)|j|if(input[2+4*j]==key and(input[3+4*j]!=left or input[4+4*j]!=right))return -1;
    }
    const bytes=16*q;if(output==null or capacity<bytes)return -2;
    var heads=[_]i32{-1}**16;var sizes=[_]i32{0}**16;
    var keys=[_]i64{-1}**32;var next=[_]i32{-1}**32;
    var statuses=[_]i64{0}**QMAX;var places=[_]i64{-1}**QMAX;var live:usize=0;
    for(0..q)|i|{
        const base=1+4*i;const op=input[base];const key=input[base+1];const lb:usize=@intCast(input[base+2]);const rb:usize=8+@as(usize,@intCast(input[base+3]));
        var found:i32= -1;var fb:usize=0;
        for([_]usize{lb,rb})|bucket|{var x=heads[bucket];while(x>=0):(x=next[@intCast(x)]){if(keys[@intCast(x)]==key){found=x;fb=bucket;break;}}if(found>=0)break;}
        if(op==0){if(found>=0){statuses[i]=0;continue;}if(live==32)return -3;
            const use_left=sizes[lb]<=sizes[rb];const bucket=if(use_left)lb else rb;var node:usize=0;while(keys[node]>=0):(node+=1){}
            keys[node]=key;next[node]=heads[bucket];heads[bucket]=@intCast(node);sizes[bucket]+=1;live+=1;statuses[i]=1;places[i]=if(use_left)0 else 1;
        }else if(op==1){statuses[i]=if(found>=0)1 else 0;
        }else if(found>=0){var previous:i32= -1;var x=heads[fb];while(x!=found):(x=next[@intCast(x)]){previous=x;}
            if(previous<0)heads[fb]=next[@intCast(x)] else next[@intCast(previous)]=next[@intCast(x)];keys[@intCast(x)]= -1;next[@intCast(x)]= -1;sizes[fb]-=1;live-=1;statuses[i]=1;
        }
    }
    for(0..q)|i|{put(output,16*i,statuses[i]);put(output,16*i+8,places[i]);}
    return @intCast(bytes);
}
