fn appendUint(b:*[2048]u8,used:*usize,value0:u32) void {var digits:[10]u8=undefined;var count:usize=0;var value=value0;if(value==0){b[used.*]='0';used.*+=1;return;}while(value>0){digits[count]='0'+@as(u8,@intCast(value%10));count+=1;value/=10;}while(count>0){count-=1;b[used.*]=digits[count];used.*+=1;}}
export fn optimal_job_scheduling(v:[*]const i64,n:usize,out:[*]u8,cap:usize)i64{
 if(n<4 or n>194 or v[0]<1 or v[0]>16 or v[1]<1 or v[1]>8)return -1;const p:usize=@intCast(v[0]);const m:usize=@intCast(v[1]);if(n!=2+p*m+m*m)return -1;for(2..n)|i|{if(v[i]<0 or v[i]>1000)return -1;}
 var cost=[_]u32{0}**128;for(0..m)|j|cost[j]=@intCast(v[2+j]);for(1..p)|i|{for(0..m)|j|{var best:u32=1000000000;for(0..m)|k|{const candidate=cost[(i-1)*m+k]+@as(u32,@intCast(v[2+p*m+k*m+j]))+@as(u32,@intCast(v[2+i*m+j]));if(candidate<best)best=candidate;}cost[i*m+j]=best;}}
 var b:[2048]u8=undefined;var used:usize=0;for(0..p)|i|{if(i>0){b[used]='\n';used+=1;}for(0..m)|j|{if(j>0){b[used]=',';used+=1;}appendUint(&b,&used,cost[i*m+j]);}}if(used>cap)return -2;@memcpy(out[0..used],b[0..used]);return @intCast(used);
}
