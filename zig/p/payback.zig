export fn payback(v:[*c]const i64,n:usize)i64{
 if(v==null||n<1||n>129||v[0]<0||v[0]>128||n!=@as(usize,@intCast(v[0]))+1)return -2;
 var total:i64=0;for(1..n)|i|{if(v[i]<-1000000 or v[i]>1000000)return -2;total+=v[i];if(total>=0)return @intCast(i-1);}return -1;
}
