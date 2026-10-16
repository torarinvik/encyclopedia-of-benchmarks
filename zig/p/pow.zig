export fn pow_algorithm(v:[*c]const i64,n:usize)f64{
 if(v==null||n!=2||v[0]<-1000||v[0]>1000||v[1]<-8||v[1]>12)return -1.0e300;
 var result:f64=1.0;var i:i64=1;while(i<=v[1]):(i+=1){result*=@floatFromInt(v[0]);}return result;
}
