in vec2 vTextureCoord;
in vec4 vColor;

uniform sampler2D uTexture;
uniform sampler2D uExtraTexture;
uniform float uTime;
uniform float uProgress;
uniform int uDebug;

float mod289(float x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 mod289(vec4 x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 perm(vec4 x){return mod289(((x * 34.0) + 1.0) * x);}

float noise(vec3 p){
    vec3 a = floor(p);
    vec3 d = p - a;
    d = d * d * (3.0 - 2.0 * d);

    vec4 b = a.xxyy + vec4(0.0, 1.0, 0.0, 1.0);
    vec4 k1 = perm(b.xyxy);
    vec4 k2 = perm(k1.xyxy + b.zzww);

    vec4 c = k2 + a.zzzz;
    vec4 k3 = perm(c);
    vec4 k4 = perm(c + 1.0);

    vec4 o1 = fract(k3 * (1.0 / 41.0));
    vec4 o2 = fract(k4 * (1.0 / 41.0));

    vec4 o3 = o2 * d.z + o1 * (1.0 - d.z);
    vec2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

    return o4.y * d.y + o4.x * (1.0 - d.y);
}

void main(void)
{
   
    float noiseVelocity = 0.01;

    vec4 fg = texture2D(uTexture, vTextureCoord);

    float displacementStrength = .09;  
          
    float scaleUV = 8.0;
    vec2 uv = vTextureCoord.xy;

    vec2 noiseUV = uv;

    // uniform scaling of noise
    noiseUV *= scaleUV;

    // move noise
    float z = uTime * noiseVelocity;
    noiseUV.x += uTime * noiseVelocity;
    noiseUV.y += uTime * noiseVelocity;

    // calculate intensity of distortion at different places
    float intensity = noise(vec3(noiseUV, z));

    // dispersion values
    vec3 dispersion = vec3(1.00, 1.02, 1.05) * 3.0;

    // relate dispersion to intensity of distortion
    dispersion *= intensity;

    vec2 uv_r = uv + noise(vec3(noiseUV, dispersion.x)) * displacementStrength * intensity;
    vec2 uv_g = uv + noise(vec3(noiseUV, dispersion.y)) * displacementStrength * intensity;
    vec2 uv_b = uv + noise(vec3(noiseUV, dispersion.z)) * displacementStrength * intensity;


    float color_r = texture2D(uTexture, uv_r).r;
    float color_g = texture2D(uTexture, uv_g).g;
    float color_b = texture2D(uTexture, uv_b).b;


    vec4 color = vec4(color_r, color_g, color_b, 1.0);
    if(uDebug == 1) {
        color = vec4(intensity, intensity, intensity, 1.0);
    }
    gl_FragColor = color;

}