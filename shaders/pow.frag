#version 460 core
precision highp float;
precision highp int;

in vec2 uv_pos;
out vec4 fragColor;

// Random work values
// First 2 bytes will be overwritten by texture pixel position
// Second 2 bytes will be modified if the canvas size is greater than 256x256
uniform uvec4 u_work0;
// Last 4 bytes remain as generated externally
uniform uvec4 u_work1;

// Defined separately from uint v[32] below as the original value is required
// to calculate the second uint32 of the digest for threshold comparison
const uint BLAKE2B_IV32_1 = 1779033703u; // Decimal equivalent of 0x6A09E667

// Both buffers represent 16 uint64s as 32 uint32s
// because that's what GLSL offers, just like Javascript

// Compression buffer, intialized to 2 instances of the initialization vector
// Values converted from hex to decimal
uint v[32] = uint[32](
    4072541440u, 1779033703u, 2227341883u, 3144134277u,
    4270124843u, 1013904242u, 1595750897u, 2773480762u,
    2917565393u, 1359893631u, 725511199u,  2600822924u,
    4215669611u, 528734635u,  324845945u,  1541459225u,
    4089326856u, 1779033703u, 2227341883u, 3144134277u,
    4270124843u, 1013904242u, 1595750897u, 2773480762u,
    2917565433u, 1359893631u, 725511199u,  2600822924u,
    79302292u,   3762393684u, 324845945u,  1541459225u
);

// Input data buffer
uint m[32];

// SIGMA values (unchanged as they're already decimal)
const int SIGMA82[192] = int[192](
    0,2,4,6,8,10,12,14,16,18,20,22,24,26,28,30,28,20,8,16,18,30,26,12,2,24,
    0,4,22,14,10,6,22,16,24,0,10,4,30,26,20,28,6,12,14,2,18,8,14,18,6,2,26,
    24,22,28,4,12,10,20,8,0,30,16,18,0,10,14,4,8,20,30,28,2,22,24,12,16,6,
    26,4,24,12,20,0,22,16,6,8,26,14,10,30,28,2,18,24,10,2,30,28,26,8,20,0,
    14,12,6,18,4,16,22,26,22,14,28,24,2,6,18,10,0,30,8,16,12,4,20,12,30,28,
    18,22,6,0,16,24,4,26,14,2,8,20,10,20,4,16,8,14,12,2,10,30,22,18,28,6,24,
    26,0,0,2,4,6,8,10,12,14,16,18,20,22,24,26,28,30,28,20,8,16,18,30,26,12,
    2,24,0,4,22,14,10,6
);

// 64-bit unsigned addition within the compression buffer
void add_uint64(int a, uint b0, uint b1) {
    uint o0 = v[a] + b0;
    uint o1 = v[a + 1] + b1;
    if (v[a] > 4294967295u - b0) { // 0xFFFFFFFFu in decimal
        o1++;
    }
    v[a] = o0;
    v[a + 1] = o1;
}

void add_uint64(int a, int b) {
    add_uint64(a, v[b], v[b+1]);
}

// G Mixing function
void B2B_G(int a, int b, int c, int d, int ix, int iy) {
    add_uint64(a, b);
    add_uint64(a, m[ix], m[ix + 1]);

    uint xor0 = v[d] ^ v[a];
    uint xor1 = v[d + 1] ^ v[a + 1];
    v[d] = xor1;
    v[d + 1] = xor0;

    add_uint64(c, d);

    xor0 = v[b] ^ v[c];
    xor1 = v[b + 1] ^ v[c + 1];
    v[b] = (xor0 >> 24) ^ (xor1 << 8);
    v[b + 1] = (xor1 >> 24) ^ (xor0 << 8);

    add_uint64(a, b);
    add_uint64(a, m[iy], m[iy + 1]);

    xor0 = v[d] ^ v[a];
    xor1 = v[d + 1] ^ v[a + 1];
    v[d] = (xor0 >> 16) ^ (xor1 << 16);
    v[d + 1] = (xor1 >> 16) ^ (xor0 << 16);

    add_uint64(c, d);

    xor0 = v[b] ^ v[c];
    xor1 = v[b + 1] ^ v[c + 1];
    v[b] = (xor1 >> 31) ^ (xor0 << 1);
    v[b + 1] = (xor0 >> 31) ^ (xor1 << 1);
}

void main() {
    int i;
    uint uv_x = uint(uv_pos.x * float(iResolution.x - 1));
    uint uv_y = uint(uv_pos.y * float(iResolution.y - 1));
    uint x_pos = uv_x % 256u;
    uint y_pos = uv_y % 256u;
    uint x_index = (uv_x - x_pos) / 256u;
    uint y_index = (uv_y - y_pos) / 256u;

    // First 2 work bytes are the x,y pos within the 256x256 area
    m[0] = (x_pos ^ (y_pos << 8) ^ ((u_work0.b ^ x_index) << 16) ^ ((u_work0.a ^ y_index) << 24));
    m[1] = (u_work1.r ^ (u_work1.g << 8) ^ (u_work1.b << 16) ^ (u_work1.a << 24));

    // Block hash - Replace these with actual decimal values based on your reverseHex values
    // You'll need to convert each hex value to decimal constants
    m[2] = 0u; // Replace with decimal equivalent of reverseHex.slice(56,64)
    m[3] = 0u; // Replace with decimal equivalent of reverseHex.slice(48,56)
    m[4] = 0u; // Replace with decimal equivalent of reverseHex.slice(40,48)
    m[5] = 0u; // Replace with decimal equivalent of reverseHex.slice(32,40)
    m[6] = 0u; // Replace with decimal equivalent of reverseHex.slice(24,32)
    m[7] = 0u; // Replace with decimal equivalent of reverseHex.slice(16,24)
    m[8] = 0u; // Replace with decimal equivalent of reverseHex.slice(8,16)
    m[9] = 0u; // Replace with decimal equivalent of reverseHex.slice(0,8)

    // Twelve rounds of mixing
    for(i = 0; i < 12; i++) {
        B2B_G(0, 8, 16, 24, SIGMA82[i * 16 + 0], SIGMA82[i * 16 + 1]);
        B2B_G(2, 10, 18, 26, SIGMA82[i * 16 + 2], SIGMA82[i * 16 + 3]);
        B2B_G(4, 12, 20, 28, SIGMA82[i * 16 + 4], SIGMA82[i * 16 + 5]);
        B2B_G(6, 14, 22, 30, SIGMA82[i * 16 + 6], SIGMA82[i * 16 + 7]);
        B2B_G(0, 10, 20, 30, SIGMA82[i * 16 + 8], SIGMA82[i * 16 + 9]);
        B2B_G(2, 12, 22, 24, SIGMA82[i * 16 + 10], SIGMA82[i * 16 + 11]);
        B2B_G(4, 14, 16, 26, SIGMA82[i * 16 + 12], SIGMA82[i * 16 + 13]);
        B2B_G(6, 8, 18, 28, SIGMA82[i * 16 + 14], SIGMA82[i * 16 + 15]);
    }

    // Threshold test
    if((BLAKE2B_IV32_1 ^ v[1] ^ v[17]) > threshold) {
        fragColor = vec4(
            float(x_index + 1u)/255., 
            float(y_index + 1u)/255.,
            float(x_pos)/255.,
            float(y_pos)/255.
        );
    }
}