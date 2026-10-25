/* Clean-room bounded port of Rodinia Myocyte's kernel_cam RHS; see package LICENSE.txt. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define CAM_INPUT_LENGTH 22
#define CAM_INVALID (-1.0e300)

static float cam_f32(int64_t raw) { return (float)raw / 1000000.0f; }
static float cam_add(float a, float b) { return a + b; }
static float cam_sub(float a, float b) { return a - b; }
static float cam_mul(float a, float b) { return a * b; }
static float cam_div(float a, float b) { return a / b; }

double rodinia_myocyte_cam_rhs(const int64_t *input, size_t length) {
    if (input == NULL || length != CAM_INPUT_LENGTH) return CAM_INVALID;
    const int64_t ca_raw = input[0], k_raw = input[1], mg_raw = input[2];
    if (ca_raw < 0 || ca_raw > 100000000 || k_raw < 100000000 || k_raw > 200000000 ||
        mg_raw < 500000 || mg_raw > 5000000) return CAM_INVALID;
    for (size_t i = 3; i < CAM_INPUT_LENGTH; ++i)
        if (input[i] < 0 || input[i] > 10000000) return CAM_INVALID;

    const float Ca = cam_f32(ca_raw), K = cam_f32(k_raw), Mg = cam_f32(mg_raw);
    const float Btot = cam_f32(input[3]);
    const float CaMKIItot = cam_f32(input[4]);
    const float CaNtot = cam_f32(input[5]);
    const float PP1tot = cam_f32(input[6]);
    float s[15];
    for (size_t i = 0; i < 15; ++i) s[i] = cam_f32(input[7 + i]);
    const float CaM=s[0], Ca2CaM=s[1], Ca4CaM=s[2], CaMB=s[3], Ca2CaMB=s[4], Ca4CaMB=s[5];
    const float Pb2=s[6], Pb=s[7], Pt=s[8], Pt2=s[9], Pa=s[10];
    const float Ca4CaN=s[11], CaMCa4CaN=s[12], Ca2CaMCa4CaN=s[13], Ca4CaMCa4CaN=s[14];

    float Kd02, Kd24;
    if (Mg <= 1.0f) {
        Kd02 = (float)(0.0025 * (1.0 + (double)K / 0.94 - (double)Mg / 0.012) *
                       (1.0 + (double)K / 8.1 + (double)Mg / 0.022));
        Kd24 = (float)(0.128 * (1.0 + (double)K / 0.64 + (double)Mg / 0.0014) *
                       (1.0 + (double)K / 13.0 - (double)Mg / 0.153));
    } else {
        Kd02 = (float)(0.0025 * (1.0 + (double)K / 0.94 - 1.0 / 0.012 + ((double)Mg - 1.0) / 0.060) *
                       (1.0 + (double)K / 8.1 + 1.0 / 0.022 + ((double)Mg - 1.0) / 0.068));
        Kd24 = (float)(0.128 * (1.0 + (double)K / 0.64 + 1.0 / 0.0014 + ((double)Mg - 1.0) / 0.005) *
                       (1.0 + (double)K / 13.0 - 1.0 / 0.153 + ((double)Mg - 1.0) / 0.150));
    }
    if (!(Kd02 > 0.0f) || !(Kd24 > 0.0f) || !isfinite(Kd02) || !isfinite(Kd24)) return CAM_INVALID;

    const float k20=10.0f, k02=cam_div(k20,Kd02), k42=500.0f, k24=cam_div(k42,Kd24);
    const float k0Boff=0.0014f, k0Bon=(float)((double)k0Boff/0.2);
    const float k2Boff=cam_div(k0Boff,100.0f), k2Bon=k0Bon, k4Boff=k2Boff, k4Bon=k0Bon;
    const float k20B=cam_div(k20,100.0f), k02B=k02, k42B=k42, k24B=k24;
    const float kbi=2.2f, kib=(float)((double)kbi/33.5e-3), kpp1=1.72f, Kmpp1=11.5f;
    const float kib2=kib, kb2i=cam_mul(kib2,5.0f), kb24=k24;
    const float kb42=(float)((double)k42*33.5e-3/5.0), kta=cam_div(kbi,1000.0f), kat=kib;
    const float kt42=(float)((double)k42*33.5e-6/5.0), kt24=k24, kat2=kib, kt2a=cam_mul(kib,5.0f);
    const float kcanCaoff=1.0f, kcanCaon=(float)((double)kcanCaoff/0.5);
    const float kcanCaM4on=46.0f, kcanCaM4off=0.0013f, kcanCaM2on=kcanCaM4on;
    const float kcanCaM2off=cam_mul(2508.0f,kcanCaM4off), kcanCaM0on=kcanCaM4on;
    const float kcanCaM0off=cam_mul(165.0f,kcanCaM2off), k02can=k02;
    const float k20can=cam_div(k20,165.0f), k24can=k24, k42can=cam_div(k20,2508.0f);

    const double ca2=(double)Ca*(double)Ca;
    const float rcn02=(float)((double)k02*ca2*(double)CaM-(double)k20*(double)Ca2CaM);
    const float rcn24=(float)((double)k24*ca2*(double)Ca2CaM-(double)k42*(double)Ca4CaM);
    const float B=cam_sub(cam_sub(cam_sub(Btot,CaMB),Ca2CaMB),Ca4CaMB);
    const float rcn02B=(float)((double)k02B*ca2*(double)CaMB-(double)k20B*(double)Ca2CaMB);
    const float rcn24B=(float)((double)k24B*ca2*(double)Ca2CaMB-(double)k42B*(double)Ca4CaMB);
    const float rcn0B=cam_sub(cam_mul(cam_mul(k0Bon,CaM),B),cam_mul(k0Boff,CaMB));
    const float rcn2B=cam_sub(cam_mul(cam_mul(k2Bon,Ca2CaM),B),cam_mul(k2Boff,Ca2CaMB));
    const float rcn4B=cam_sub(cam_mul(cam_mul(k4Bon,Ca4CaM),B),cam_mul(k4Boff,Ca4CaMB));

    float Ca2CaN=cam_sub(cam_sub(cam_sub(cam_sub(CaNtot,Ca4CaN),CaMCa4CaN),Ca2CaMCa4CaN),Ca4CaMCa4CaN);
    const float rcnCa4CaN=(float)((double)kcanCaon*ca2*(double)Ca2CaN-(double)kcanCaoff*(double)Ca4CaN);
    const float rcn02CaN=(float)((double)k02can*ca2*(double)CaMCa4CaN-(double)k20can*(double)Ca2CaMCa4CaN);
    const float rcn24CaN=(float)((double)k24can*ca2*(double)Ca2CaMCa4CaN-(double)k42can*(double)Ca4CaMCa4CaN);
    const float rcn0CaN=cam_sub(cam_mul(cam_mul(kcanCaM0on,CaM),Ca4CaN),cam_mul(kcanCaM0off,CaMCa4CaN));
    const float rcn2CaN=cam_sub(cam_mul(cam_mul(kcanCaM2on,Ca2CaM),Ca4CaN),cam_mul(kcanCaM2off,Ca2CaMCa4CaN));
    const float rcn4CaN=cam_sub(cam_mul(cam_mul(kcanCaM4on,Ca4CaM),Ca4CaN),cam_mul(kcanCaM4off,Ca4CaMCa4CaN));

    float Pix=cam_sub(cam_sub(cam_sub(cam_sub(cam_sub(1.0f,Pb2),Pb),Pt),Pt2),Pa);
    const float rcnCKib2=cam_sub(cam_mul(cam_mul(kib2,Ca2CaM),Pix),cam_mul(kb2i,Pb2));
    const float rcnCKb2b=(float)((double)kb24*ca2*(double)Pb2-(double)kb42*(double)Pb);
    const float rcnCKib=cam_sub(cam_mul(cam_mul(kib,Ca4CaM),Pix),cam_mul(kbi,Pb));
    float T=cam_add(cam_add(cam_add(Pb,Pt),Pt2),Pa);
    const double Td=(double)T;
    const float kbt=(float)(0.055*Td+0.0074*Td*Td+0.015*Td*Td*Td);
    const float rcnCKbt=cam_sub(cam_mul(kbt,Pb),cam_div(cam_mul(cam_mul(kpp1,PP1tot),Pt),cam_add(Kmpp1,cam_mul(CaMKIItot,Pt))));
    const float rcnCKtt2=cam_sub(cam_mul(kt42,Pt),(float)((double)kt24*ca2*(double)Pt2));
    const float rcnCKta=cam_sub(cam_mul(kta,Pt),cam_mul(cam_mul(kat,Ca4CaM),Pa));
    const float rcnCKt2a=cam_sub(cam_mul(kt2a,Pt2),cam_mul(cam_mul(kat2,Ca2CaM),Pa));
    const float rcnCKt2b2=cam_div(cam_mul(cam_mul(kpp1,PP1tot),Pt2),cam_add(Kmpp1,cam_mul(CaMKIItot,Pt2)));
    const float rcnCKai=cam_div(cam_mul(cam_mul(kpp1,PP1tot),Pa),cam_add(Kmpp1,cam_mul(CaMKIItot,Pa)));

    float d[16];
    d[0]=(float)(1e-3*(double)cam_sub(cam_sub(-rcn02,rcn0B),rcn0CaN));
    float term=cam_add(cam_sub(cam_sub(cam_sub(rcn02,rcn24),rcn2B),rcn2CaN),cam_mul(CaMKIItot,cam_add(-rcnCKib2,rcnCKt2a)));
    d[1]=(float)(1e-3*(double)term);
    term=cam_add(cam_sub(cam_sub(rcn24,rcn4B),rcn4CaN),cam_mul(CaMKIItot,cam_add(-rcnCKib,rcnCKta)));
    d[2]=(float)(1e-3*(double)term);
    d[3]=(float)(1e-3*(double)cam_sub(rcn0B,rcn02B));
    d[4]=(float)(1e-3*(double)cam_sub(cam_add(rcn02B,rcn2B),rcn24B));
    d[5]=(float)(1e-3*(double)cam_add(rcn24B,rcn4B));
    d[6]=(float)(1e-3*(double)cam_add(cam_sub(rcnCKib2,rcnCKb2b),rcnCKt2b2));
    d[7]=(float)(1e-3*(double)cam_sub(cam_add(rcnCKib,rcnCKb2b),rcnCKbt));
    d[8]=(float)(1e-3*(double)cam_sub(cam_sub(rcnCKbt,rcnCKta),rcnCKtt2));
    d[9]=(float)(1e-3*(double)cam_sub(cam_sub(rcnCKtt2,rcnCKt2a),rcnCKt2b2));
    d[10]=(float)(1e-3*(double)cam_sub(cam_add(rcnCKta,rcnCKt2a),rcnCKai));
    d[11]=(float)(1e-3*(double)cam_sub(cam_sub(cam_sub(rcnCa4CaN,rcn0CaN),rcn2CaN),rcn4CaN));
    d[12]=(float)(1e-3*(double)cam_sub(rcn0CaN,rcn02CaN));
    d[13]=(float)(1e-3*(double)cam_sub(cam_add(rcn2CaN,rcn02CaN),rcn24CaN));
    d[14]=(float)(1e-3*(double)cam_add(rcn4CaN,rcn24CaN));
    const float com_inner1=cam_mul(cam_mul(2.0f,CaMKIItot),cam_sub(rcnCKtt2,rcnCKb2b));
    float com_sum=cam_add(rcn02,rcn24);
    com_sum=cam_add(com_sum,rcn02B);
    com_sum=cam_add(com_sum,rcn24B);
    com_sum=cam_add(com_sum,rcnCa4CaN);
    com_sum=cam_add(com_sum,rcn02CaN);
    com_sum=cam_add(com_sum,rcn24CaN);
    const float com_inner2=cam_mul(2.0f,com_sum);
    d[15]=(float)(1e-3*(double)cam_sub(com_inner1,com_inner2));
    double checksum=0.0;
    for (size_t i=0;i<16;i++) {
        if (!isfinite(d[i])) d[i]=0.0001f;
        checksum += (double)(i+1)*(double)d[i];
    }
    return checksum;
}
