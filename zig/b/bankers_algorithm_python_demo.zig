const MAX_N: usize = 16;
const MAX_M: usize = 8;

/// Preserve duplicate-need bookkeeping in the pinned Python demonstration.
export fn bankers_algorithm_python_demo(values: [*]const i64, length: usize) i64 {
    if (length < 5 or length > 266) return -1;
    const v=values[0..length];
    if(v[0]<1 or v[0]>16 or v[1]<1 or v[1]>8)return -1;
    const n:usize=@intCast(v[0]);const m:usize=@intCast(v[1]);
    const aoff=2+m;const moff=aoff+n*m;
    if(length!=moff+n*m)return -1;
    var work=[_]i64{0}**MAX_M;
    for(0..m)|r|{const x=v[2+r];if(x<0 or x>100)return -1;work[r]=x;}
    for(0..n)|p|{for(0..m)|r|{const i=p*m+r;const a=v[aoff+i];const x=v[moff+i];if(a<0 or a>100 or x<0 or x>100 or a>x)return -1;work[r]-=a;}}
    for(0..m)|r|{if(work[r]<0)return -1;}
    var first=[_]usize{0}**MAX_N;var remaining=[_]usize{0}**MAX_N;
    for(0..n)|p|{first[p]=p;remaining[p]=p;for(0..p)|q|{var equal=true;for(0..m)|r|{const pi=p*m+r;const qi=q*m+r;if(v[moff+pi]-v[aoff+pi]!=v[moff+qi]-v[aoff+qi]){equal=false;break;}}if(equal){first[p]=first[q];break;}}}
    var count=n;while(count>0){var selected=count;for(0..count)|i|{const p=remaining[i];var feasible=true;for(0..m)|r|{const j=p*m+r;if(v[moff+j]-v[aoff+j]>work[r]){feasible=false;break;}}if(feasible){selected=i;break;}}
        if(selected==count)return 0;const mapped=first[remaining[selected]];for(0..m)|r|{work[r]+=v[aoff+mapped*m+r];}var i=selected+1;while(i<count):(i+=1){remaining[i-1]=remaining[i];}count-=1;
    }
    return 1;
}
