export fn nagel_schrekenberg(v:[*]const i64,n:usize,out:[*]u8,cap:usize)i64{
 if(n<5 or v[0]<2 or v[0]>32 or v[1]<0 or v[1]>16 or v[2]<0 or v[2]>5 or n!=@as(usize,@intCast(v[0]))+3)return -1;const cells:usize=@intCast(v[0]);const steps:usize=@intCast(v[1]);var row=[_]i64{-1}**32;for(0..cells)|i|{if(v[i+3]<-1 or v[i+3]>5)return -1;row[i]=v[i+3];}const need=cells*(steps+1);if(need>cap)return -2;var pos:usize=0;for(0..cells)|j|{out[pos]=@intCast(row[j]+1);pos+=1;}
 for(0..steps)|_|{var next=[_]i64{-1}**32;for(0..cells)|i|{if(row[i]!=-1){var distance:usize=0;var j=i+1;while(j<cells and row[j]==-1):(j+=1){distance+=1;}if(j==cells){j=0;while(row[j]==-1){distance+=1;j+=1;}}var speed=@min(row[i]+1,v[2]);speed=@min(speed,@as(i64,@intCast(distance))-1);next[i]=speed;}}var moved=[_]i64{-1}**32;for(0..cells)|i|{if(next[i]!=-1){moved[(i+@as(usize,@intCast(next[i])))%cells]=next[i];}}row=next;for(0..cells)|j|{row[j]=moved[j];out[pos]=@intCast(row[j]+1);pos+=1;}}
 return @intCast(pos);
}
