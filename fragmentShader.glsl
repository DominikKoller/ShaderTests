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
    
    // Prelude
    vec4 fg = texture2D(uTexture, vTextureCoord);
    vec2 uv = vTextureCoord.xy;
    vec2 noiseUV = uv;

    // Parameters
    float noiseVelocity = 0.5;
    float displacementStrength = 0.1; 
    float scaleUV = 8.0;


    // – – – – – – – – – – – – – – M A S K I N G – – – – – – – – – – – – – – 
    float rampWidth = 0.2;
    float maskStart = 0.0;
    float sustain = 0.4;
    // make it loop
    float offset = (uv.y + uv.x) / 2.0 - uTime * 0.1;
    // offset = offset * 2.0 - 4.0;
    offset = mod(offset, 1.0);
    float mask = smoothstep(maskStart, maskStart+rampWidth, offset) - smoothstep(maskStart+rampWidth+sustain, maskStart+rampWidth*2.0+sustain, offset);
   

    // – – – – – – – – – – – – – – D I S T O R T I O N – – – – – – – – – – – – – – 
    // uniform scaling of noise
    noiseUV *= scaleUV;

    // animate noise
    float z = uTime * noiseVelocity;
    // noiseUV.x += uTime * noiseVelocity;
    // noiseUV.y += uTime * noiseVelocity;

    // calculate intensity of distortion at different places
    float intensity = noise(vec3(noiseUV, z));
    intensity *= mask;

    // dispersion values
    vec3 dispersion = vec3(1.00, 1.02, 1.05);
    // relate dispersion to intensity of distortion = noise value
    dispersion *=  pow(noise(vec3(noiseUV, 1.0)), 2.0) * 4.0;

    float noiseDebug = noise(vec3(noiseUV, z));

    vec2 uv_r = uv + noise(vec3(noiseUV, z + dispersion.x)) * displacementStrength * intensity;
    vec2 uv_g = uv + noise(vec3(noiseUV, z + dispersion.y)) * displacementStrength * intensity;
    vec2 uv_b = uv + noise(vec3(noiseUV, z + dispersion.z)) * displacementStrength * intensity;


    float color_r = texture2D(uExtraTexture, uv_r).r; // I CHANGED THIS to try the extra texture
    float color_g = texture2D(uTexture, uv_g).g;
    float color_b = texture2D(uTexture, uv_b).b;


    vec4 color = vec4(color_r, color_g, color_b, 1.0);
    if(uDebug == 1) {
        color = vec4(noiseDebug, noiseDebug, noiseDebug, 1.0);
    }
    gl_FragColor = color;

}