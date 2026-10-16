module pow;
fn double pow_algorithm(long* v,usz n) @export("pow_algorithm") {
 if(v==null||n!=2||v[0] < -1000||v[0]>1000||v[1]<-8||v[1]>12)return -1.0e300;
 double result=1.0;
 for(long i=1;i<=v[1];i+=1)result*=v[0].double();
 return result;
}
