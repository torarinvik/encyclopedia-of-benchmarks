export fn length_of_list(v:[*]const i64,n:usize)i64{if(n>64)return -1;for(0..n)|i|{if(v[i]<0 or v[i]>100000)return -1;}return @intCast(n);}
