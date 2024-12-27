// $MinimumShaderProfile: ps_3_0
// Display 2020 gamut in ITP

const static float stim = 0.5;
#define Mode 1

//Mode 1 - Full Gamut
//Mode 2 - Red Focus
//Mode 3 - Blue Focus
//Mode 4 - Green Focus

//PQ constants
const static float m1 = 2610.0 / 16384;
const static float m2 = 2523.0 / 32;
const static float m1inv = 16384 / 2610.0;
const static float m2inv = 32 / 2523.0;
const static float c1 = 3424 / 4096.0;
const static float c2 = 2413 / 128.0;
const static float c3 = 2392 / 128.0;

sampler s0;
 
// Convert PQ to linear RGB
float3 pq_to_lin(float3 pq) { 
  float3 p = pow(pq, m2inv);
  float3 d = max(p - c1, 0) / (c2 - c3 * p);
  return pow(d, m1inv);
}

// Convert linear RGB to PQ
float3 lin_to_pq(float3 lin) {
  float3 y = lin; 
  float3 p = (c1 + c2 * pow(y, m1)) / (1 + c3 * pow(y, m1));
  return pow(p, m2);
}

// Convert linear RGB to LMS
float3 rgb_to_lms(float3 rgb) {
    float L = (1688 * rgb.r + 2146 * rgb.g + 262 * rgb.b) / 4096;
    float M = (683 * rgb.r + 2951 * rgb.g + 462 * rgb.b) / 4096;
    float S = (99 * rgb.r + 309 * rgb.g + 3688 * rgb.b) / 4096;
    return float3(L, M, S);
}

// Convert LMS to linear RGB
float3 lms_to_rgb(float3 lms) {
    float R = (14076.34101999 * lms.r - 10266.42787802 * lms.g + 286.086858031688 * lms.b) / 4096;
    float G = (-3241.28585973 * lms.r + 8124.82745054 * lms.g - 787.54159081 * lms.b) / 4096;
    float B = (-106.29078913 * lms.r - 405.15057546 * lms.g + 4607.44136459 * lms.b) / 4096;
    return float3(R, G, B);
}

// Convert PQ LMS to ITP
float3 pq_lms_to_itp(float3 lms) {
    float I = 0.5 * lms.x + 0.5 * lms.y;
    float T = (6610 * lms.x - 13613 * lms.y + 7003 * lms.z) / 8192;
    float P = (17933 * lms.x - 17390 * lms.y - 543 * lms.z) / 4096;
    return float3(I, T, P);
}

// Convert ITP to PQ LMS
float3 itp_to_pq_lms(float3 itp) {
	itp.y = itp.y * 2;
    float L = itp.x + 35.26261571/4096 * itp.y + 454.77734401/4096 * itp.z;
    float M = itp.x - 35.26261571/4096 * itp.y - 454.77734401/4096 * itp.z;
    float S = itp.x + 2293.88835107/4096 * itp.y - 1313.28890875/4096 * itp.z;
    return float3(L, M, S);
}

float4 main(float2 tex : TEXCOORD0) : COLOR {
  float4 c0 = tex2D(s0, tex);

  float xmin = -0.3;
  float xmax = 0.465;
  float ymin = -0.235;
  float ymax = 0.18;

  #if Mode == 2
  xmin = 0.1;
  #elif Mode == 3
  xmax = 0;
  ymin = 0;
  #elif Mode == 4
  xmin = -.18;
  xmax = 0;
  ymax = 0;
  #endif

  float I = 0.734;
  float T = lerp(ymin, ymax, tex.y);
  float P = lerp(xmin, xmax, tex.x);
  
  float3 itp1 = float3(I,T,P);
  float3 pqlms1 = itp_to_pq_lms(itp1);
  float3 lms1 = pq_to_lin(pqlms1);
  float3 lin1 = lms_to_rgb(lms1);
  if (any(lin1 < 0)) return float4(0, 0, 0, 1);
  lin1 = lin1/max(lin1[0],max(lin1[1],lin1[2]))*pq_to_lin(stim);
  float3 rgb1 = lin_to_pq(lin1);
  
  if (any(rgb1 < 0)) return float4(0, 0, 0, 1);
  return float4(rgb1.r, rgb1.g, rgb1.b, 1);
}
