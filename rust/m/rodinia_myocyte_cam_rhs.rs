/// Clean-room bounded port of Rodinia Myocyte's `kernel_cam` RHS.
/// The complete applicable notice is in benchmarks/m/rodinia_myocyte_cam_rhs/LICENSE.txt.
#[no_mangle]
pub extern "C" fn rodinia_myocyte_cam_rhs(input: *const i64, length: usize) -> f64 {
    const BAD: f64 = -1.0e300;
    if input.is_null() || length != 22 { return BAD; }
    let x = unsafe { std::slice::from_raw_parts(input, length) };
    if x[0] < 0 || x[0] > 100_000_000 || x[1] < 100_000_000 || x[1] > 200_000_000 ||
        x[2] < 500_000 || x[2] > 5_000_000 { return BAD; }
    if x[3..].iter().any(|&v| v < 0 || v > 10_000_000) { return BAD; }
    let f = |v: i64| -> f32 { v as f32 / 1_000_000.0f32 };
    let (ca, k, mg) = (f(x[0]), f(x[1]), f(x[2]));
    let (btot, camkii, cantot, pp1) = (f(x[3]), f(x[4]), f(x[5]), f(x[6]));
    let s: [f32; 15] = std::array::from_fn(|i| f(x[7 + i]));
    let (cam, ca2cam, ca4cam, camb, ca2camb, ca4camb) = (s[0], s[1], s[2], s[3], s[4], s[5]);
    let (pb2, pb, pt, pt2, pa) = (s[6], s[7], s[8], s[9], s[10]);
    let (ca4can, camca4can, ca2camca4can, ca4camca4can) = (s[11], s[12], s[13], s[14]);
    let (kd02, kd24) = if mg <= 1.0f32 {
        ((0.0025 * (1.0 + k as f64 / 0.94 - mg as f64 / 0.012) * (1.0 + k as f64 / 8.1 + mg as f64 / 0.022)) as f32,
         (0.128 * (1.0 + k as f64 / 0.64 + mg as f64 / 0.0014) * (1.0 + k as f64 / 13.0 - mg as f64 / 0.153)) as f32)
    } else {
        ((0.0025 * (1.0 + k as f64 / 0.94 - 1.0/0.012 + (mg as f64-1.0)/0.060) * (1.0 + k as f64/8.1 + 1.0/0.022 + (mg as f64-1.0)/0.068)) as f32,
         (0.128 * (1.0 + k as f64/0.64 + 1.0/0.0014 + (mg as f64-1.0)/0.005) * (1.0 + k as f64/13.0 - 1.0/0.153 + (mg as f64-1.0)/0.150)) as f32)
    };
    if !(kd02 > 0.0 && kd24 > 0.0) { return BAD; }
    let (k20, k42) = (10.0f32, 500.0f32);
    let (k02, k24) = (k20/kd02, k42/kd24);
    let (k0boff, k0bon) = (0.0014f32, (0.0014f64/0.2) as f32);
    let (k2boff, k2bon, k4boff, k4bon) = (k0boff/100.0, k0bon, k0boff/100.0, k0bon);
    let (k20b, k02b, k42b, k24b) = (k20/100.0, k02, k42, k24);
    let (kbi, kib, kpp1, kmpp1) = (2.2f32, (2.2f64/33.5e-3) as f32, 1.72f32, 11.5f32);
    let (kib2, kb2i, kb24, kb42) = (kib, kib*5.0, k24, (500.0f64*33.5e-3/5.0) as f32);
    let (kta, kat, kt42, kt24, kat2, kt2a) = (kbi/1000.0, kib, (500.0f64*33.5e-6/5.0) as f32, k24, kib, kib*5.0);
    let (kcan_caoff, kcan_caon) = (1.0f32, (1.0f64/0.5) as f32);
    let (kcan_cam4on, kcan_cam4off) = (46.0f32, 0.0013f32);
    let (kcan_cam2on, kcan_cam2off) = (46.0f32, 2508.0f32*0.0013f32);
    let (kcan_cam0on, kcan_cam0off) = (46.0f32, 165.0f32*(2508.0f32*0.0013f32));
    let (k02can, k20can, k24can, k42can) = (k02, k20/165.0, k24, k20/2508.0);
    let ca_sq = ca as f64 * ca as f64;
    let rcn02 = (k02 as f64*ca_sq*cam as f64-k20 as f64*ca2cam as f64) as f32;
    let rcn24 = (k24 as f64*ca_sq*ca2cam as f64-k42 as f64*ca4cam as f64) as f32;
    let b = ((btot-camb)-ca2camb)-ca4camb;
    let rcn02b = (k02b as f64*ca_sq*camb as f64-k20b as f64*ca2camb as f64) as f32;
    let rcn24b = (k24b as f64*ca_sq*ca2camb as f64-k42b as f64*ca4camb as f64) as f32;
    let rcn0b = (k0bon*cam*b)-(k0boff*camb);
    let rcn2b = (k2bon*ca2cam*b)-(k2boff*ca2camb);
    let rcn4b = (k4bon*ca4cam*b)-(k4boff*ca4camb);
    let ca2can = ((((cantot-ca4can)-camca4can)-ca2camca4can)-ca4camca4can);
    let rcn_ca4can = (kcan_caon as f64*ca_sq*ca2can as f64-kcan_caoff as f64*ca4can as f64) as f32;
    let rcn02can = (k02can as f64*ca_sq*camca4can as f64-k20can as f64*ca2camca4can as f64) as f32;
    let rcn24can = (k24can as f64*ca_sq*ca2camca4can as f64-k42can as f64*ca4camca4can as f64) as f32;
    let rcn0can = (kcan_cam0on*cam*ca4can)-(kcan_cam0off*camca4can);
    let rcn2can = (kcan_cam2on*ca2cam*ca4can)-(kcan_cam2off*ca2camca4can);
    let rcn4can = (kcan_cam4on*ca4cam*ca4can)-(kcan_cam4off*ca4camca4can);
    let pix = ((((1.0f32-pb2)-pb)-pt)-pt2)-pa;
    let rcn_ckib2 = (kib2*ca2cam*pix)-(kb2i*pb2);
    let rcn_ckb2b = (kb24 as f64*ca_sq*pb2 as f64-kb42 as f64*pb as f64) as f32;
    let rcn_ckib = (kib*ca4cam*pix)-(kbi*pb);
    let total = ((pb+pt)+pt2)+pa;
    let kbt = (0.055*total as f64+0.0074*(total as f64)*(total as f64)+0.015*(total as f64)*(total as f64)*(total as f64)) as f32;
    let rcn_ckbt = (kbt*pb)-((kpp1*pp1*pt)/(kmpp1+camkii*pt));
    let rcn_cktt2 = (kt42*pt)-(kt24 as f64*ca_sq*pt2 as f64) as f32;
    let rcn_ckta = (kta*pt)-(kat*ca4cam*pa);
    let rcn_ckt2a = (kt2a*pt2)-(kat2*ca2cam*pa);
    let rcn_ckt2b2 = (kpp1*pp1*pt2)/(kmpp1+camkii*pt2);
    let rcn_ckai = (kpp1*pp1*pa)/(kmpp1+camkii*pa);
    let d0 = (1e-3*((-rcn02-rcn0b)-rcn0can) as f64) as f32;
    let term1 = (((rcn02-rcn24)-rcn2b)-rcn2can)+camkii*(-rcn_ckib2+rcn_ckt2a);
    let d1 = (1e-3*term1 as f64) as f32;
    let term2 = ((rcn24-rcn4b)-rcn4can)+camkii*(-rcn_ckib+rcn_ckta);
    let d2 = (1e-3*term2 as f64) as f32;
    let d3 = (1e-3*(rcn0b-rcn02b) as f64) as f32;
    let d4 = (1e-3*((rcn02b+rcn2b)-rcn24b) as f64) as f32;
    let d5 = (1e-3*(rcn24b+rcn4b) as f64) as f32;
    let d6 = (1e-3*((rcn_ckib2-rcn_ckb2b)+rcn_ckt2b2) as f64) as f32;
    let d7 = (1e-3*((rcn_ckib+rcn_ckb2b)-rcn_ckbt) as f64) as f32;
    let d8 = (1e-3*((rcn_ckbt-rcn_ckta)-rcn_cktt2) as f64) as f32;
    let d9 = (1e-3*((rcn_cktt2-rcn_ckt2a)-rcn_ckt2b2) as f64) as f32;
    let d10 = (1e-3*((rcn_ckta+rcn_ckt2a)-rcn_ckai) as f64) as f32;
    let d11 = (1e-3*(((rcn_ca4can-rcn0can)-rcn2can)-rcn4can) as f64) as f32;
    let d12 = (1e-3*(rcn0can-rcn02can) as f64) as f32;
    let d13 = (1e-3*((rcn2can+rcn02can)+rcn24can) as f64) as f32;
    let d14 = (1e-3*(rcn4can+rcn24can) as f64) as f32;
    let com_sum = ((((((rcn02+rcn24)+rcn02b)+rcn24b)+rcn_ca4can)+rcn02can)+rcn24can);
    let d15 = (1e-3*((2.0f32*camkii*(rcn_cktt2-rcn_ckb2b)-2.0f32*com_sum) as f64)) as f32;
    let ds = [d0,d1,d2,d3,d4,d5,d6,d7,d8,d9,d10,d11,d12,d13,d14,d15];
    ds.iter().enumerate().map(|(i, &v)| (i as f64+1.0)*v as f64).sum()
}
