const MAX_FAN: usize = 8;
const MAX_INPUT_LENGTH: usize = 1 + 8 * (MAX_FAN + 1);

fn validBox(v: [*]const i64, at: usize) bool {
    for (0..4) |d| if (v[at+d] < -8 or v[at+d] > 8 or v[at+4+d] < -8 or v[at+4+d] > 8 or v[at+d] >= v[at+4+d]) return false;
    return true;
}
fn volumeAt(v: [*]const i64, at: usize) i64 { var p:i64=1;for(0..4)|d|p*=v[at+4+d]-v[at+d];return p; }
fn unionVolume(v: [*]const i64, left: usize, right: usize) i64 {
    var p:i64=1;for(0..4)|d|p*=@max(v[left+4+d],v[right+4+d])-@min(v[left+d],v[right+d]);return p;
}
fn penalty(v: [*]const i64, seed: usize, entry: usize) i64 { return unionVolume(v,seed,entry)-volumeAt(v,seed); }

export fn versabench_dbms_partition_entries(raw: [*c]const i64, length: usize) i64 {
    if (raw == null or length < 1 or length > MAX_INPUT_LENGTH + 1) return -1;
    const v: [*]const i64 = raw;
    if (v[0] < 2 or v[0] > MAX_FAN) return -1;
    const fan: usize = @intCast(v[0]);const count=fan+1;if(length!=1+8*count)return -1;
    for(0..count)|i|if(!validBox(v,1+8*i))return -1;
    var seed_a:usize=0;var seed_b:usize=1;var largest=unionVolume(v,1,9);
    for(0..count)|i|{for(i+1..count)|j|{const candidate=unionVolume(v,1+8*i,1+8*j);if(candidate>largest){seed_a=i;seed_b=j;largest=candidate;}}}
    const a_at=1+8*seed_a;const b_at=1+8*seed_b;var size_a:usize=1;var size_b:usize=1;var mask:i64=@as(i64,1)<<@intCast(seed_a);
    for(0..count)|i|{if(i==seed_a or i==seed_b)continue;const at=1+8*i;
        if(size_a<fan and size_b<fan){if(penalty(v,a_at,at)<penalty(v,b_at,at)){mask|=@as(i64,1)<<@intCast(i);size_a+=1;}else{size_b+=1;}}
        else if(size_a>=fan and size_b<fan){size_b+=1;}else if(size_b>=fan and size_a<fan){mask|=@as(i64,1)<<@intCast(i);size_a+=1;}else{return -1;}
    }
    return mask;
}
