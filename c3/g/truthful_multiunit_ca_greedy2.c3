module truthful_multiunit_ca_greedy2;
extern fn double pow(double base, double exponent);
const int MAX_ITEMS=6; const int MAX_BIDDERS=12; const int MAX_INPUT=32; const int MAX_OUTPUT=104;
fn void put_i64(char* out, usz at, long value){ulong bits=(ulong)value;for(usz b=0;b<8;b++){out[at+b]=(char)(bits&255);bits>>=8;}}
fn long truthful_multiunit_ca_greedy2(long* a,usz n,char* out,usz cap) @export("truthful_multiunit_ca_greedy2") {
 if(a==null||n<(usz)5||n>(usz)MAX_INPUT||a[0]<2||a[0]>MAX_ITEMS||a[1]<1||a[1]>MAX_BIDDERS)return -1;
 int r=(int)a[0],k=(int)a[1];if(n!=(usz)(2+r+2*k))return -1;int[MAX_ITEMS] b;double[MAX_ITEMS] y;int B=100;
 for(int e=0;e<r;e++){if(a[2+e]<1||a[2+e]>8)return -1;b[e]=(int)a[2+e];if(b[e]<B)B=b[e];y[e]=1.0/(double)b[e];}
 int[MAX_BIDDERS] value;int[MAX_BIDDERS] mask;for(int i=0;i<k;i++){long v=a[2+r+2*i],m=a[3+r+2*i];if(v<1||v>100||m<1||m>=(1<<r))return -1;value[i]=(int)v;mask[i]=(int)m;}
 double threshold=pow(2.718281828459045,(double)B)*(double)r;bool[MAX_BIDDERS] chosen=zeroed;int[MAX_BIDDERS] order=zeroed;int count=0;
 while(count<k){int best=-1;double best_score=-1.0;for(int i=0;i<k;i++)if(!chosen[i]){double den=0.0;for(int e=0;e<r;e++)if((mask[i]&(1<<e))!=0)den+=y[e];double score=(double)value[i]/den;if(best<0||score>best_score){best=i;best_score=score;}}if(best<0)break;chosen[best]=true;order[count]=best;count+=1;for(int e=0;e<r;e++)if((mask[best]&(1<<e))!=0)y[e]*=pow(threshold,1.0/(double)b[e]);double dual=0.0;for(int e=0;e<r;e++)dual+=(double)b[e]*y[e];if(dual>=threshold)break;}
 usz bytes=(usz)(8*(1+count));if(out==null||cap<bytes)return -2;char[MAX_OUTPUT] staged=zeroed;put_i64(&staged[0],0,(long)count);for(int i=0;i<count;i++)put_i64(&staged[0],(usz)(8*(i+1)),(long)order[i]);for(usz i=0;i<bytes;i++)out[i]=staged[i];return (long)bytes;
}
