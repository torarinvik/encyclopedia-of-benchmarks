module clarke_wright_savings_cvrp;
import "core:c";

fn void reverse_route(int* routes, usz row, usz length) {
    for (usz left=0; left<length/2; left++) {
        usz right=length-1-left;
        int value=routes[row*7+left]; routes[row*7+left]=routes[row*7+right]; routes[row*7+right]=value;
    }
}
fn int compare_routes(int* a, usz alen, int* b, usz blen) {
    usz shared=alen<blen?alen:blen;
    for (usz i=0;i<shared;i++) {if(a[i]<b[i])return -1;if(a[i]>b[i])return 1;}
    if(alen<blen)return -1;if(alen>blen)return 1;return 0;
}
fn void put_i64(char* output, long value) {
    ulong bits=(ulong)value;
    for(usz i=0;i<8;i++)output[i]=(char)(bits>>(8*i));
}

fn long clarke_wright_savings_cvrp(long* input, usz length, char* output, usz capacity)
    @export("clarke_wright_savings_cvrp") {
    if(input==null || length<2 || length>74)return -1;
    long n0=input[0],cap0=input[1];
    if(n0<0 || n0>7 || cap0<1 || cap0>100)return -1;
    usz n=(usz)n0,width=n+1;
    if(length!=2+n+width*width)return -1;
    long[8] demand;for(usz i=0;i<8;i++)demand[i]=0;
    for(usz c=1;c<=n;c++){long d=input[1+c];if(d<1 || d>cap0)return -1;demand[c]=d;}
    long[64] distances;
    for(usz i=0;i<64;i++)distances[i]=0;
    usz offset=2+n;
    for(usz i=0;i<width;i++)for(usz j=0;j<width;j++){
        long d=input[offset+i*width+j];if(d<0 || d>1000 || (i==j && d!=0))return -1;distances[i*8+j]=d;
    }
    for(usz i=0;i<width;i++)for(usz j=i+1;j<width;j++)if(distances[i*8+j]!=distances[j*8+i])return -1;

    int[49] routes;usz[7] route_length;long[7] load;bool[7] active;
    for(usz i=0;i<49;i++)routes[i]=0;
    for(usz i=0;i<7;i++){route_length[i]=0;load[i]=0;active[i]=false;}
    for(usz r=0;r<n;r++){routes[r*7]= (int)(r+1);route_length[r]=1;load[r]=demand[r+1];active[r]=true;}
    long[21] saving;usz[21] pair_i,pair_j;usz pair_count=0;
    for(usz i=1;i<=n;i++)for(usz j=i+1;j<=n;j++){
        saving[pair_count]=distances[i]+distances[j]-distances[i*8+j];pair_i[pair_count]=i;pair_j[pair_count]=j;pair_count++;
    }
    for(usz i=0;i<pair_count;i++)for(usz j=i+1;j<pair_count;j++){
        bool swap=saving[j]>saving[i] || (saving[j]==saving[i] && (pair_i[j]<pair_i[i] || (pair_i[j]==pair_i[i] && pair_j[j]<pair_j[i])));
        if(swap){long sv=saving[i];saving[i]=saving[j];saving[j]=sv;usz t=pair_i[i];pair_i[i]=pair_i[j];pair_i[j]=t;t=pair_j[i];pair_j[i]=pair_j[j];pair_j[j]=t;}
    }
    for(usz p=0;p<pair_count;p++){
        if(saving[p]<=0)break;
        usz ri=7,rj=7,pi=0,pj=0;
        for(usz r=0;r<n;r++)if(active[r])for(usz at=0;at<route_length[r];at++){
            if(routes[r*7+at]==(int)pair_i[p]){ri=r;pi=at;}
            if(routes[r*7+at]==(int)pair_j[p]){rj=r;pj=at;}
        }
        if(ri==rj || ri==7 || rj==7)continue;
        if((pi!=0 && pi+1!=route_length[ri]) || (pj!=0 && pj+1!=route_length[rj]) || load[ri]+load[rj]>cap0)continue;
        if(pi==0)reverse_route(&routes[0],ri,route_length[ri]);
        if(pj+1==route_length[rj])reverse_route(&routes[0],rj,route_length[rj]);
        for(usz at=0;at<route_length[rj];at++)routes[ri*7+route_length[ri]+at]=routes[rj*7+at];
        route_length[ri]+=route_length[rj];load[ri]+=load[rj];active[rj]=false;route_length[rj]=0;load[rj]=0;
    }
    int[49] final_routes;usz[7] final_length;usz count=0;
    for(usz i=0;i<49;i++)final_routes[i]=0;
    for(usz r=0;r<n;r++)if(active[r]){
        bool reverse_first=false;
        for(usz at=0;at<route_length[r];at++){int a=routes[r*7+at],b=routes[r*7+route_length[r]-1-at];if(a!=b){reverse_first=a>b;break;}}
        if(reverse_first)reverse_route(&routes[0],r,route_length[r]);
        for(usz at=0;at<route_length[r];at++)final_routes[count*7+at]=routes[r*7+at];
        final_length[count]=route_length[r];count++;
    }
    for(usz i=0;i<count;i++)for(usz j=i+1;j<count;j++)if(compare_routes(&final_routes[i*7],final_length[i],&final_routes[j*7],final_length[j])>0){
        for(usz k=0;k<7;k++){int t=final_routes[i*7+k];final_routes[i*7+k]=final_routes[j*7+k];final_routes[j*7+k]=t;}
        usz t=final_length[i];final_length[i]=final_length[j];final_length[j]=t;
    }
    long[15] words;usz word_count=0;words[word_count++]=(long)count;
    for(usz r=0;r<count;r++){words[word_count++]=(long)final_length[r];for(usz at=0;at<final_length[r];at++)words[word_count++]=final_routes[r*7+at];}
    usz bytes=word_count*8;if(output==null || capacity<bytes)return -2;
    for(usz i=0;i<word_count;i++)put_i64(output+i*8,words[i]);return (long)bytes;
}
