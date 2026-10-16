proc ic_555_timer*(v:ptr UncheckedArray[int64],n:csize_t):cdouble {.cdecl,exportc:"ic_555_timer".}=
 if v.isNil or n!=4:return -1.0e300
 let mode=v[0];let r1=v[1];let r2=v[2];let c=v[3]
 if (mode!=0 and mode!=1) or r1<1 or r1>1000000 or r2<1 or r2>1000000 or (mode==0 and (c<1 or c>1000000)) or (mode==1 and (c<0 or c>1000000)):return -1.0e300
 if mode==0:return (1.44/((r1+2*r2).float*c.float))*1e6
 ((r1+r2).float/(r1+2*r2).float)*100.0
