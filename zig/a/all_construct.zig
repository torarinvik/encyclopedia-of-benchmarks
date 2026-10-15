const MAX_TARGET: usize = 6;
const MAX_WORDS: usize = 4;
const MAX_WAYS: usize = 4096;

export fn all_construct(input: ?[*]const i64, length: usize, output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length < 2) return -1;
    const a=input.?[0..length];if(a[0]<0 or a[0]>6)return -1;
    const n:usize=@intCast(a[0]);for(0..n)|i|{if(a[i+1]<97 or a[i+1]>122)return -1;}
    const wc_slot=1+n;if(wc_slot>=length or a[wc_slot]<0 or a[wc_slot]>4)return -1;
    const words:usize=@intCast(a[wc_slot]);var starts=[_]usize{0}**MAX_WORDS;var word_lengths=[_]usize{0}**MAX_WORDS;var cursor=wc_slot+1;
    for(0..words)|w|{if(cursor>=length or a[cursor]<1 or a[cursor]>6)return -1;const wl:usize=@intCast(a[cursor]);cursor+=1;if(cursor+wl>length)return -1;starts[w]=cursor;word_lengths[w]=wl;for(0..wl)|j|{if(a[cursor+j]<97 or a[cursor+j]>122)return -1;}cursor+=wl;}
    if(cursor!=length)return -1;
    var paths:[(MAX_TARGET+1)*MAX_WAYS*MAX_TARGET]u8=@splat(0);var path_lengths:[(MAX_TARGET+1)*MAX_WAYS]u8=@splat(0);var counts:[MAX_TARGET+1]usize=@splat(0);counts[0]=1;
    for(0..n)|pos|{for(0..words)|w|{const wl=word_lengths[w];if(wl>n-pos)continue;var matched=true;for(0..wl)|j|{if(a[pos+1+j]!=a[starts[w]+j])matched=false;}if(!matched)continue;const ending=pos+wl;for(0..counts[pos])|row|{const dest=counts[ending];if(dest>=MAX_WAYS)return -1;counts[ending]+=1;const src=(pos*MAX_WAYS+row)*MAX_TARGET;const dst=(ending*MAX_WAYS+dest)*MAX_TARGET;const plen:usize=path_lengths[pos*MAX_WAYS+row];@memcpy(paths[dst..dst+plen],paths[src..src+plen]);paths[dst+plen]=@intCast(w);path_lengths[ending*MAX_WAYS+dest]=@intCast(plen+1);}}}
    var required:usize=0;for(0..counts[n])|row|{const plen:usize=path_lengths[n*MAX_WAYS+row];required+=1;for(0..plen)|k|{const w:usize=paths[(n*MAX_WAYS+row)*MAX_TARGET+k];required+=1+word_lengths[w];}}
    if(required>output_capacity or (required>0 and output==null))return -2;if(counts[n]==0)return 0;
    const out=output.?[0..required];var written:usize=0;for(0..counts[n])|row|{const base=(n*MAX_WAYS+row)*MAX_TARGET;const plen:usize=path_lengths[n*MAX_WAYS+row];out[written]=@intCast(plen);written+=1;for(0..plen)|k|{const w:usize=paths[base+k];const wl=word_lengths[w];out[written]=@intCast(wl);written+=1;for(0..wl)|j|{out[written]=@intCast(a[starts[w]+j]);written+=1;}}}
    return @intCast(counts[n]);
}
