module bankers_algorithm_python_demo;
const usz MAX_N = 16, MAX_M = 8;

fn long bankers_algorithm_python_demo_impl(long* v, usz length)
{
    if (v == null || length < 5 || length > 266) return -1;
    long nv=v[0], mv=v[1]; if(nv<1||nv>16||mv<1||mv>8)return -1;
    usz n=(usz)nv,m=(usz)mv,aoff=2+m,moff=aoff+n*m; if(length!=moff+n*m)return -1;
    long[8] work=zeroed;
    for(usz r=0;r<m;r++){long x=v[2+r];if(x<0||x>100)return -1;work[r]=x;}
    for(usz p=0;p<n;p++)for(usz r=0;r<m;r++){usz i=p*m+r;long a=v[aoff+i],x=v[moff+i];if(a<0||a>100||x<0||x>100||a>x)return -1;work[r]-=a;}
    for(usz r=0;r<m;r++)if(work[r]<0)return -1;
    usz[16] first=zeroed, remaining=zeroed;
    for(usz p=0;p<n;p++){first[p]=p;remaining[p]=p;for(usz q=0;q<p;q++){bool equal=true;for(usz r=0;r<m;r++){usz pi=p*m+r,qi=q*m+r;if(v[moff+pi]-v[aoff+pi]!=v[moff+qi]-v[aoff+qi]){equal=false;break;}}if(equal){first[p]=first[q];break;}}}
    usz count=n;while(count>0){usz selected=count;for(usz i=0;i<count;i++){usz p=remaining[i];bool feasible=true;for(usz r=0;r<m;r++){usz j=p*m+r;if(v[moff+j]-v[aoff+j]>work[r]){feasible=false;break;}}if(feasible){selected=i;break;}}
        if(selected==count)return 0;usz mapped=first[remaining[selected]];for(usz r=0;r<m;r++)work[r]+=v[aoff+mapped*m+r];for(usz i=selected+1;i<count;i++)remaining[i-1]=remaining[i];count--;
    }
    return 1;
}
fn long bankers_algorithm_python_demo(long* v, usz length) @export("bankers_algorithm_python_demo") { return bankers_algorithm_python_demo_impl(v,length); }
