export fn one_hot_encode(v:[*]const i64,n:usize,out:[*]u8,cap:usize)i64{
 if(n<2 or n>33 or v[0]<1 or v[0]>32)return -1;const rows:usize=@intCast(v[0]);if(n!=rows+1)return -1;var present=[_]bool{false}**26;
 for(0..rows)|i|{const x=v[i+1];if(x<0 or x>25)return -1;present[@intCast(x)]=true;}
 var map=[_]usize{0}**26;var cols:usize=0;for(0..26)|i|{if(present[i]){map[i]=cols;cols+=1;}}
 const need=rows*cols;if(need>cap)return -2;for(0..rows)|r|{for(0..cols)|c|{out[r*cols+c]=@intFromBool(map[@intCast(v[r+1])]==c);}}
 return @intCast(need);
}
