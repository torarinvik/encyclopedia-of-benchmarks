const W:usize=32;const L:usize=16;const Q:usize=16;const NN:usize=513;const NO:usize=8721;
const Node = struct {
    child: [26]i16 = @splat(-1),
    terminal: bool = false,
};
fn collect(nodes:*[NN]Node,at:usize,path:*[L]usize,depth:usize,out:*[NO]i64,used:*usize,count:*usize)void{
 if(nodes[at].terminal){out[used.*]=@intCast(depth);used.*+=1;for(0..depth)|j|{out[used.*]=@intCast('a'+path[j]);used.*+=1;}count.*+=1;}
 for(0..26)|c|{const child=nodes[at].child[c];if(child>=0){path[depth]=c;collect(nodes,@intCast(child),path,depth+1,out,used,count);}}
}
fn put(out:[*c]u8,index:usize,value:i64)void{const bits:u64=@bitCast(value);for(0..8)|b|out[index*8+b]=@truncate(bits>>@intCast(8*b));}
pub export fn autocomplete_using_trie(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
 if(input==null or length<2 or input[0]<0 or input[0]>@as(i64,@intCast(W)))return -1;var nodes:[NN]Node=@splat(.{});var nc:usize=1;var pos:usize=1;
 for(0..@as(usize,@intCast(input[0])))|_|{if(pos>=length)return -1;const lv=input[pos];pos+=1;if(lv<1 or lv>@as(i64,@intCast(L)) or pos+@as(usize,@intCast(lv))>length)return -1;var at:usize=0;for(0..@as(usize,@intCast(lv)))|_|{const ch=input[pos];pos+=1;if(ch<97 or ch>122)return -1;const c:usize=@intCast(ch-97);if(nodes[at].child[c]<0){if(nc>=NN)return -1;nodes[nc]=.{};nodes[at].child[c]=@intCast(nc);nc+=1;}at=@intCast(nodes[at].child[c]);}nodes[at].terminal=true;}
 if(pos>=length)return -1;const qv=input[pos];pos+=1;if(qv<0 or qv>@as(i64,@intCast(Q)))return -1;const q:usize=@intCast(qv);var qp:[Q]usize=@splat(0);var ql:[Q]usize=@splat(0);
 for(0..q)|i|{if(pos>=length)return -1;const lv=input[pos];pos+=1;if(lv<0 or lv>@as(i64,@intCast(L)) or pos+@as(usize,@intCast(lv))>length)return -1;qp[i]=pos;ql[i]=@intCast(lv);for(0..ql[i])|j|{if(input[pos+j]<97 or input[pos+j]>122)return -1;}pos+=ql[i];}if(pos!=length)return -1;
 var values:[NO]i64=@splat(0);var used:usize=0;values[used]=@intCast(q);used+=1;for(0..q)|i|{var at:usize=0;var path:[L]usize=@splat(0);var found=true;for(0..ql[i])|j|{const c:usize=@intCast(input[qp[i]+j]-97);path[j]=c;if(nodes[at].child[c]<0){found=false;break;}at=@intCast(nodes[at].child[c]);}const cp=used;used+=1;var count:usize=0;if(found)collect(&nodes,at,&path,ql[i],&values,&used,&count);values[cp]=@intCast(count);}
 const required=used*8;if(output==null or capacity<required)return -2;for(0..used)|i|put(output,i,values[i]);return @intCast(required);
}
