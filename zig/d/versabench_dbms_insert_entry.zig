const MAX_DEPTH: usize = 2;
const MAX_CHILDREN: usize = 4;
const MAX_LEAF: usize = 3;
const MAX_WORDS: usize = 28;

fn validBox(b: [8]i64) bool {
    for (0..4) |d| if (b[d] < -8 or b[d] > 8 or b[4+d] < -8 or b[4+d] > 8 or b[d] >= b[4+d]) return false;
    return true;
}
fn unionBoxes(boxes: []const [8]i64) [8]i64 {
    var out=boxes[0];
    for (boxes[1..]) |b| { for (0..4) |d| { out[d]=@min(out[d],b[d]);out[4+d]=@max(out[4+d],b[4+d]); } }
    return out;
}
fn volume(b:[8]i64)i64{var out:i64=1;for(0..4)|d|out*=b[4+d]-b[d];return out;}
fn sameBox(a:[8]i64,b:[8]i64)bool{for(0..8)|i|if(a[i]!=b[i])return false;return true;}
fn writeI64(out:[*]u8,word:usize,value:i64)void{const bits:u64=@bitCast(value);for(0..8)|b|out[word*8+b]=@truncate(bits>>@intCast(8*b));}

export fn versabench_dbms_insert_entry(raw:?[*]const i64,length:usize,raw_output:?[*]u8,output_capacity:usize)i64{
    if(raw==null or length<11 or length>105)return -1;
    const v=raw.?[0..length];const depthv=v[0];const new_id=v[1];
    if(depthv<0 or depthv>@as(i64,MAX_DEPTH) or new_id<0 or new_id>=32)return -1;
    const depth:usize=@intCast(depthv);var incoming:[8]i64=undefined;for(0..8)|i|incoming[i]=v[2+i];if(!validBox(incoming))return -1;
    var branches:[MAX_DEPTH][MAX_CHILDREN][8]i64=undefined;
    var counts:[MAX_DEPTH]usize=@splat(0);var seen:[32]bool=@splat(false);var pos:usize=10;
    for(0..depth)|level|{if(pos>=length)return -1;const cv=v[pos];pos+=1;if(cv<1 or cv>@as(i64,MAX_CHILDREN) or pos+@as(usize,@intCast(cv))*8>length)return -1;counts[level]=@intCast(cv);
        for(0..counts[level])|i|{for(0..8)|j|branches[level][i][j]=v[pos+j];pos+=8;if(!validBox(branches[level][i]))return -1;}}
    if(pos>=length)return -1;const lv=v[pos];pos+=1;if(lv<0 or lv>@as(i64,MAX_LEAF) or (depth>0 and lv==0) or pos+@as(usize,@intCast(lv))*9>length)return -1;
    const leaf_count:usize=@intCast(lv);var leaf_boxes:[MAX_LEAF][8]i64=undefined;var leaf_ids:[MAX_LEAF]i64=undefined;
    for(0..leaf_count)|i|{for(0..8)|j|leaf_boxes[i][j]=v[pos+j];pos+=8;leaf_ids[i]=v[pos];pos+=1;if(!validBox(leaf_boxes[i]) or leaf_ids[i]<0 or leaf_ids[i]>=32)return -1;const id:usize=@intCast(leaf_ids[i]);if(seen[id])return -1;seen[id]=true;}
    if(pos!=length or seen[@intCast(new_id)])return -1;
    var choices:[MAX_DEPTH]usize=@splat(0);
    for(0..depth)|level|{var best:i64=65536;for(0..counts[level])|i|{var joined:[8]i64=undefined;for(0..4)|d|{joined[d]=@min(branches[level][i][d],incoming[d]);joined[4+d]=@max(branches[level][i][4+d],incoming[4+d]);}const p=volume(joined)-volume(branches[level][i]);if(p<best){best=p;choices[level]=i;}}}
    if(depth>0){var pre=unionBoxes(leaf_boxes[0..leaf_count]);var rev=depth;while(rev>0){rev-=1;const level=rev;if(!sameBox(branches[level][choices[level]],pre))return -1;pre=unionBoxes(branches[level][0..counts[level]]);}}
    var staged:[MAX_LEAF+1][8]i64=undefined;for(0..leaf_count)|i|staged[i]=leaf_boxes[i];staged[leaf_count]=incoming;
    var child=unionBoxes(staged[0..leaf_count+1]);var result:[MAX_WORDS]i64=undefined;var outn:usize=0;
    result[outn]=@intCast(depth);outn+=1;result[outn]=new_id;outn+=1;for(0..depth)|i|{result[outn]=@intCast(choices[i]);outn+=1;}for(0..8)|d|{result[outn]=child[d];outn+=1;}
    var rev=depth;while(rev>0){rev-=1;const level=rev;branches[level][choices[level]]=child;child=unionBoxes(branches[level][0..counts[level]]);for(0..8)|d|{result[outn]=child[d];outn+=1;}}
    const bytes=outn*8;if(raw_output==null or output_capacity<bytes)return -2;const output=raw_output.?;for(0..outn)|i|writeI64(output,i,result[i]);return @intCast(bytes);
}
