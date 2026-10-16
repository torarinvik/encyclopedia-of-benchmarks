module otsu_threshold;
fn long otsu_threshold(long*v,usz n,char*out,usz cap) @export("otsu_threshold") {
 if(v==null||n<2||v[0]<1||v[0]>32||n!=(usz)(v[0]+1))return -1;usz count=(usz)v[0];long[256] hist;
 for(usz j=0;j<count;j++){long p=v[j+1];if(p<0||p>255)return -1;hist[(usz)p]++;}
 double total=0;for(usz i=0;i<256;i++)total+=(double)i*(double)hist[i];double maxv=0,sum=0;usz wb=0,t=0;
 for(usz i=0;i<256;i++){wb+=(usz)hist[i];if(wb==0)continue;usz wf=count-wb;if(wf==0)break;sum+=(double)i*(double)hist[i];double mb=sum/(double)wb,mf=(total-sum)/(double)wf;double d=mb-mf,var=(double)wb*(double)wf*d*d;if(var>maxv){maxv=var;t=i;}}
 if(cap<count||out==null)return -2;for(usz j=0;j<count;j++)out[j]=v[j+1]>(long)t?255:0;return (long)count;
}
