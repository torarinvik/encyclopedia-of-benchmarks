module monotonic_array;
fn long monotonic_array(long* v, ulong n) @export("monotonic_array") {
 if(n>256||(v==null&&n>0))return -1;
 bool inc=true,dec=true;
 for(ulong i=0;i<n;i++)if(v[i]<-1000000000||v[i]>1000000000)return -1;
 for(ulong i=1;i<n;i++){if(v[i-1]>v[i])inc=false;if(v[i-1]<v[i])dec=false;}
 return inc||dec;
}
