export fn monotonic_array(v:[*]const i64,n:usize)i64{
 if(n>256)return -1;var inc=true;var dec=true;
 for(0..n)|i|{if(v[i]<-1000000000 or v[i]>1000000000)return -1;}
 for(1..n)|i|{if(v[i-1]>v[i])inc=false;if(v[i-1]<v[i])dec=false;}
 return if(inc or dec) 1 else 0;
}
