export fn nearest_neighbour_algorithm(v:[*]const i64,n:usize,out:[*]u8,cap:usize)i64{
 if(n<2 or n>257 or v[0]<1 or v[0]>16)return -1;const count:usize=@intCast(v[0]);if(n!=1+count*count)return -1;for(1..n)|i|{if(v[i]<0 or v[i]>1000000)return -1;}
 var seen=[_]bool{false}**16;var path=[_]usize{0}**16;var current:usize=0;
 for(0..count)|step|{path[step]=current;seen[current]=true;if(step+1<count){var best=count;var distance:i64=0;for(0..count)|j|{if(!seen[j]){const d=v[1+current*count+j];if(best==count or d<distance){best=j;distance=d;}}}current=best;}}
 var b:[64]u8=undefined;var used:usize=0;for(0..count)|i|{if(i>0){b[used]=',';used+=1;}const x=path[i];if(x>=10){b[used]='0'+@as(u8,@intCast(x/10));used+=1;}b[used]='0'+@as(u8,@intCast(x%10));used+=1;}if(used>cap)return -2;@memcpy(out[0..used],b[0..used]);return @intCast(used);
}
