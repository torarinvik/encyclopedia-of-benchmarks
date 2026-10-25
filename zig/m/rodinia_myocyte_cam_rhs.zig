// Clean-room bounded port of Rodinia Myocyte's kernel_cam RHS; notice in package LICENSE.txt.
const INPUT_LENGTH: usize = 22;
fn addf(a: f32, b: f32) f32 { @setFloatMode(.strict); return a + b; }
fn subf(a: f32, b: f32) f32 { @setFloatMode(.strict); return a - b; }
fn mulf(a: f32, b: f32) f32 { @setFloatMode(.strict); return a * b; }
fn divf(a: f32, b: f32) f32 { @setFloatMode(.strict); return a / b; }
fn decode(v: i64) f32 { return @as(f32, @floatFromInt(v)) / 1_000_000.0; }

pub export fn rodinia_myocyte_cam_rhs(values: ?[*]const i64, length: usize) f64 {
    const x = values orelse return -1.0e300;
    if (length != INPUT_LENGTH) return -1.0e300;
    if (x[0] < 0 or x[0] > 100_000_000 or x[1] < 100_000_000 or x[1] > 200_000_000 or x[2] < 500_000 or x[2] > 5_000_000) return -1.0e300;
    for (3..INPUT_LENGTH) |i| if (x[i] < 0 or x[i] > 10_000_000) return -1.0e300;
    const ca=decode(x[0]); const k=decode(x[1]); const mg=decode(x[2]);
    const btot=decode(x[3]); const camkii=decode(x[4]); const cantot=decode(x[5]); const pp1=decode(x[6]);
    var s: [15]f32=undefined; for (0..15) |i| s[i]=decode(x[7+i]);
    const cam=s[0]; const ca2cam=s[1]; const ca4cam=s[2]; const camb=s[3]; const ca2camb=s[4]; const ca4camb=s[5];
    const pb2=s[6]; const pb=s[7]; const pt=s[8]; const pt2=s[9]; const pa=s[10];
    const ca4can=s[11]; const camca4can=s[12]; const ca2camca4can=s[13]; const ca4camca4can=s[14];
    var kd02:f32=undefined; var kd24:f32=undefined;
    if (mg <= 1.0) {
        kd02=@floatCast(0.0025*(1.0+@as(f64,k)/0.94-@as(f64,mg)/0.012)*(1.0+@as(f64,k)/8.1+@as(f64,mg)/0.022));
        kd24=@floatCast(0.128*(1.0+@as(f64,k)/0.64+@as(f64,mg)/0.0014)*(1.0+@as(f64,k)/13.0-@as(f64,mg)/0.153));
    } else {
        kd02=@floatCast(0.0025*(1.0+@as(f64,k)/0.94-1.0/0.012+(@as(f64,mg)-1.0)/0.060)*(1.0+@as(f64,k)/8.1+1.0/0.022+(@as(f64,mg)-1.0)/0.068));
        kd24=@floatCast(0.128*(1.0+@as(f64,k)/0.64+1.0/0.0014+(@as(f64,mg)-1.0)/0.005)*(1.0+@as(f64,k)/13.0-1.0/0.153+(@as(f64,mg)-1.0)/0.150));
    }
    if (!(kd02>0) or !(kd24>0)) return -1.0e300;
    const k20:f32=10; const k42:f32=500; const k02=divf(k20,kd02); const k24=divf(k42,kd24);
    const k0boff:f32=0.0014; const k0bon:@TypeOf(k0boff)=@floatCast(@as(f64,k0boff)/0.2);
    const k2boff=divf(k0boff,100); const k2bon=k0bon; const k4boff=k2boff; const k4bon=k0bon;
    const k20b=divf(k20,100); const k02b=k02; const k42b=k42; const k24b=k24;
    const kbi:f32=2.2; const kib:f32=@floatCast(@as(f64,kbi)/33.5e-3); const kpp1:f32=1.72; const kmpp1:f32=11.5;
    const kib2=kib; const kb2i=mulf(kib2,5); const kb24=k24; const kb42:f32=@floatCast(500.0*33.5e-3/5.0);
    const kta=divf(kbi,1000); const kat=kib; const kt42:f32=@floatCast(500.0*33.5e-6/5.0); const kt24=k24; const kat2=kib; const kt2a=mulf(kib,5);
    const kcan_caoff:f32=1; const kcan_caon:f32=2; const kcan_cam4on:f32=46; const kcan_cam4off:f32=0.0013;
    const kcan_cam2on=kcan_cam4on; const kcan_cam2off=mulf(2508,kcan_cam4off); const kcan_cam0on=kcan_cam4on; const kcan_cam0off=mulf(165,kcan_cam2off);
    const k02can=k02; const k20can=divf(k20,165); const k24can=k24; const k42can=divf(k20,2508);
    const ca_sq=@as(f64,ca)*@as(f64,ca);
    const rcn02:f32=@floatCast(@as(f64,k02)*ca_sq*@as(f64,cam)-@as(f64,k20)*@as(f64,ca2cam));
    const rcn24:f32=@floatCast(@as(f64,k24)*ca_sq*@as(f64,ca2cam)-@as(f64,k42)*@as(f64,ca4cam));
    const b=subf(subf(subf(btot,camb),ca2camb),ca4camb);
    const rcn02b:f32=@floatCast(@as(f64,k02b)*ca_sq*@as(f64,camb)-@as(f64,k20b)*@as(f64,ca2camb));
    const rcn24b:f32=@floatCast(@as(f64,k24b)*ca_sq*@as(f64,ca2camb)-@as(f64,k42b)*@as(f64,ca4camb));
    const rcn0b=subf(mulf(mulf(k0bon,cam),b),mulf(k0boff,camb)); const rcn2b=subf(mulf(mulf(k2bon,ca2cam),b),mulf(k2boff,ca2camb)); const rcn4b=subf(mulf(mulf(k4bon,ca4cam),b),mulf(k4boff,ca4camb));
    const ca2can=subf(subf(subf(subf(cantot,ca4can),camca4can),ca2camca4can),ca4camca4can);
    const rcn_ca4can:f32=@floatCast(@as(f64,kcan_caon)*ca_sq*@as(f64,ca2can)-@as(f64,kcan_caoff)*@as(f64,ca4can));
    const rcn02can:f32=@floatCast(@as(f64,k02can)*ca_sq*@as(f64,camca4can)-@as(f64,k20can)*@as(f64,ca2camca4can));
    const rcn24can:f32=@floatCast(@as(f64,k24can)*ca_sq*@as(f64,ca2camca4can)-@as(f64,k42can)*@as(f64,ca4camca4can));
    const rcn0can=subf(mulf(mulf(kcan_cam0on,cam),ca4can),mulf(kcan_cam0off,camca4can)); const rcn2can=subf(mulf(mulf(kcan_cam2on,ca2cam),ca4can),mulf(kcan_cam2off,ca2camca4can)); const rcn4can=subf(mulf(mulf(kcan_cam4on,ca4cam),ca4can),mulf(kcan_cam4off,ca4camca4can));
    const pix=subf(subf(subf(subf(subf(@as(f32,1),pb2),pb),pt),pt2),pa);
    const rcn_ckib2=subf(mulf(mulf(kib2,ca2cam),pix),mulf(kb2i,pb2));
    const rcn_ckb2b:f32=@floatCast(@as(f64,kb24)*ca_sq*@as(f64,pb2)-@as(f64,kb42)*@as(f64,pb));
    const rcn_ckib=subf(mulf(mulf(kib,ca4cam),pix),mulf(kbi,pb));
    const total=addf(addf(addf(pb,pt),pt2),pa); const td:f64=@as(f64,total);
    const kbt:f32=@floatCast(0.055*td+0.0074*td*td+0.015*td*td*td);
    const rcn_ckbt=subf(mulf(kbt,pb),divf(mulf(mulf(kpp1,pp1),pt),addf(kmpp1,mulf(camkii,pt))));
    const rcn_cktt2=subf(mulf(kt42,pt),@as(f32,@floatCast(@as(f64,kt24)*ca_sq*@as(f64,pt2))));
    const rcn_ckta=subf(mulf(kta,pt),mulf(mulf(kat,ca4cam),pa)); const rcn_ckt2a=subf(mulf(kt2a,pt2),mulf(mulf(kat2,ca2cam),pa));
    const rcn_ckt2b2=divf(mulf(mulf(kpp1,pp1),pt2),addf(kmpp1,mulf(camkii,pt2))); const rcn_ckai=divf(mulf(mulf(kpp1,pp1),pa),addf(kmpp1,mulf(camkii,pa)));
    var d:[16]f32=undefined;
    const d0inner=subf(-rcn02,rcn0b); d[0]=@floatCast(1e-3*@as(f64,subf(d0inner,rcn0can)));
    var term=addf(subf(subf(subf(rcn02,rcn24),rcn2b),rcn2can),mulf(camkii,addf(-rcn_ckib2,rcn_ckt2a))); d[1]=@floatCast(1e-3*@as(f64,term));
    term=addf(subf(subf(rcn24,rcn4b),rcn4can),mulf(camkii,addf(-rcn_ckib,rcn_ckta))); d[2]=@floatCast(1e-3*@as(f64,term));
    d[3]=@floatCast(1e-3*@as(f64,subf(rcn0b,rcn02b))); d[4]=@floatCast(1e-3*@as(f64,subf(addf(rcn02b,rcn2b),rcn24b))); d[5]=@floatCast(1e-3*@as(f64,addf(rcn24b,rcn4b)));
    d[6]=@floatCast(1e-3*@as(f64,addf(subf(rcn_ckib2,rcn_ckb2b),rcn_ckt2b2))); d[7]=@floatCast(1e-3*@as(f64,subf(addf(rcn_ckib,rcn_ckb2b),rcn_ckbt)));
    d[8]=@floatCast(1e-3*@as(f64,subf(subf(rcn_ckbt,rcn_ckta),rcn_cktt2))); d[9]=@floatCast(1e-3*@as(f64,subf(subf(rcn_cktt2,rcn_ckt2a),rcn_ckt2b2))); d[10]=@floatCast(1e-3*@as(f64,subf(addf(rcn_ckta,rcn_ckt2a),rcn_ckai)));
    const d11a=subf(rcn_ca4can,rcn0can); const d11b=subf(d11a,rcn2can); d[11]=@floatCast(1e-3*@as(f64,subf(d11b,rcn4can)));
    d[12]=@floatCast(1e-3*@as(f64,subf(rcn0can,rcn02can))); d[13]=@floatCast(1e-3*@as(f64,addf(addf(rcn2can,rcn02can),rcn24can))); d[14]=@floatCast(1e-3*@as(f64,addf(rcn4can,rcn24can)));
    var comsum=addf(rcn02,rcn24); comsum=addf(comsum,rcn02b); comsum=addf(comsum,rcn24b); comsum=addf(comsum,rcn_ca4can); comsum=addf(comsum,rcn02can); comsum=addf(comsum,rcn24can);
    const cterm=mulf(mulf(@as(f32,2),camkii),subf(rcn_cktt2,rcn_ckb2b)); d[15]=@floatCast(1e-3*@as(f64,subf(cterm,mulf(@as(f32,2),comsum))));
    var checksum:f64=0; for (0..16) |i| checksum += @as(f64,@floatFromInt(i+1))*@as(f64,d[i]); return checksum;
}
