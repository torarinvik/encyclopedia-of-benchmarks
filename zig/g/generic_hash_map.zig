fn hashValue(h0:u64,value:i64)u64{
 var h=h0;const bits=@as(u64,@bitCast(value));for(0..8)|i|{h=(h^((bits>>@as(u6,@intCast(8*i)))&255))*%0x100000001b3;}return h;
}
export fn generic_hash_map(a:[*c]const i64,n:usize)i64{
 if(a==null or n<1 or n>385)return -1;const count=a[0];if(count<0 or count>128 or n!=1+3*@as(usize,@intCast(count)))return -1;
 var keys:[64]i64=undefined;var vals:[64]i64=undefined;var next:[64]i32=undefined;var head:[128]i32=undefined;var active:[64]bool=undefined;
 for(0..64)|i|{next[i]=-1;active[i]=false;}for(0..128)|i|{head[i]=-1;}
 var size:usize=0;var bc:usize=16;var h:u64=0xcbf29ce484222325;
 for(0..@as(usize,@intCast(count)))|oi|{
  const op=a[1+3*oi];const key=a[2+3*oi];const value=a[3+3*oi];if(key<0 or key>1000000)return -1;
  var b:usize=@intCast(@mod(key,@as(i64,@intCast(bc))));var found:i32=-1;var j=head[b];while(j>=0){const q:usize=@intCast(j);if(keys[q]==key){found=j;break;}j=next[q];}
  if(op==0){if(value < (-1000000) or value > 1000000)return -1;if(found>=0){vals[@intCast(found)]=value;}else{if(size>=64)return -1;var slot:usize=0;while(active[slot]){slot+=1;}active[slot]=true;keys[slot]=key;vals[slot]=value;next[slot]=head[b];head[b]=@intCast(slot);size+=1;if(size*4>bc*3 and bc<128){bc*=2;for(0..128)|i|{head[i]=-1;}for(0..64)|q|{if(active[q]){b=@intCast(@mod(keys[q],@as(i64,@intCast(bc))));next[q]=head[b];head[b]=@intCast(q);}}}}}
  else if(op==1 or op==3){if(value!=0)return -1;const observed:i64=if(op==1)(if(found>=0)vals[@intCast(found)] else -9223372036854775807-1)else if(found>=0)1 else 0;h=hashValue(h,observed);}
  else if(op==2){if(value!=0)return -1;if(found>=0){var prev:i32=-1;j=head[b];while(j>=0){const q:usize=@intCast(j);if(j==found){if(prev<0){head[b]=next[q];}else{next[@intCast(prev)]=next[q];}break;}prev=j;j=next[q];}active[@intCast(found)]=false;size-=1;}}
  else if(op==4){if(key!=0 or value!=0)return -1;h=hashValue(h,@intCast(size));}else{return -1;}
 }
 h=hashValue(h,@intCast(size));var used:[64]bool=@splat(false);for(0..size)|_|{var best:?usize=null;for(0..64)|i|{if(active[i] and !used[i] and (best==null or keys[i]<keys[best.?]))best=i;}const q=best.?;used[q]=true;h=hashValue(hashValue(h,keys[q]),vals[q]);}return @bitCast(h);
}
