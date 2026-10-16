export fn diffie_hellman(v: [*]const i64, n: usize) i64 {
    if(n!=4)return -1; const g=v[0];const a=v[1];const b=v[2];const p=v[3];
    if(p<2 or p>6700417 or g<1 or g>=p or a<1 or a>=p or b<1 or b>=p)return -1;
    var d:i64=2;while(d*d<=p):(d+=1){if(@rem(p,d)==0)return -1;}
    var r:i64=1; var x=g; var e=a; while(e>0){if(@rem(e,2)==1)r=@rem(r*x,p);x=@rem(x*x,p);e=@divTrunc(e,2);}
    var y=r; e=b;r=1;while(e>0){if(@rem(e,2)==1)r=@rem(r*y,p);y=@rem(y*y,p);e=@divTrunc(e,2);}return r;
}
