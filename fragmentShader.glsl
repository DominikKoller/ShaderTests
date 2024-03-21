in vec2 vTextureCoord;
in vec4 vColor;

uniform sampler2D uTexture;
uniform sampler2D uExtraTexture;
uniform float uTime;
uniform float uProgress;
uniform float uDisplacementStrength;
uniform float uRampAttack;
uniform float uRampSustain;
uniform float uRampDecay;
uniform float uNoiseFrequency;
uniform float uNoiseVelocity;
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




    // – – – – – – – – – – – – – – M A S K I N G – – – – – – – – – – – – – – 
    

    float rampLength = uRampAttack + uRampSustain + uRampDecay;

    //make sure the values sum up to 1.0
    float rampAttack = uRampAttack/rampLength;
    float rampSustain = uRampSustain/rampLength;
    float rampDecay = uRampDecay/rampLength;

    vec2 uvRamp = uv + noise(vec3(uv, uv.x) * uNoiseFrequency);
    // mix x and y to create diagonal movement
    float offset = uvRamp.y - uProgress*2.3;

    // start so the ramp is not in center of canvas
    offset += 0.8;

    // make it loop at a later point, so that the gradient doesnt show in idle
    // offset = mod(offset, 1.5);

    float mask = smoothstep(0.0, rampAttack, offset) - smoothstep(rampAttack+rampSustain, 1.0, offset);
    
    // – – – – – – – – – – – – – – D I S T O R T I O N – – – – – – – – – – – – – – 
    // Parameters
    // float noiseVelocity = 0.01;
    // float displacementStrength = 0.1; 
    // float scaleUV = 8.0;

    // uniform scaling of noise
    noiseUV *= uNoiseFrequency;

    // animate noise
    float z = uTime * uNoiseVelocity;
    noiseUV.x += uTime * uNoiseVelocity;
    noiseUV.y += uTime * uNoiseVelocity;

    // calculate intensity of distortion at different places
    float intensity = noise(vec3(noiseUV, z));

    // combine influencese for displacement
    float blendedIntensity =  uDisplacementStrength * intensity * mask;

    // dispersion values
    vec3 dispersion = vec3(1.00, 1.02, 1.05);

    // relate dispersion to intensity of distortion = noise value
    dispersion *=  pow(noise(vec3(noiseUV, 1.0)), 2.0) * 4.0;

    // add displacement to uvs and center it
    vec2 uv_r = uv + noise(vec3(noiseUV, z + dispersion.x)) * blendedIntensity - blendedIntensity * 0.5;
    vec2 uv_g = uv + noise(vec3(noiseUV, z + dispersion.y)) * blendedIntensity - blendedIntensity * 0.5;
    vec2 uv_b = uv + noise(vec3(noiseUV, z + dispersion.z)) * blendedIntensity - blendedIntensity * 0.5;


    float color_r = texture2D(uTexture, uv_r).r;
    float color_g = texture2D(uTexture, uv_g).g;
    float color_b = texture2D(uTexture, uv_b).b;
    vec4 color = vec4(color_r, color_g, color_b, 1.0);
    
    // – – – – – – – – – – – – – – R E F L E C T I O N – – – – – – – – – – – – – – 
    float reflectionScale = 0.6;
    float opacityNoiseScale = 2.0;
    
    vec2 uvRefl = uv + noise(vec3(uv * reflectionScale + vec2(.2, .7) , z)) * uDisplacementStrength * intensity;
    vec2 uvOpacityRefl = uvRefl * opacityNoiseScale;

    vec4 reflColor = texture2D(uExtraTexture, uvRefl );
    float alpha = noise(vec3(uvOpacityRefl, z) * opacityNoiseScale);
    alpha = smoothstep(0.5, 0.9, alpha) * 0.75;



    // – – – – – – – – – – – – – – M I X I N G – – – – – – – – – – – – – – 
    
    color = mix( color, reflColor, alpha * mask);

    if(uDebug == 1) {
        color = vec4(mask, mask, mask, 1.0);
        // color = vec4(alpha, alpha, alpha, 1.0);
    }
    gl_FragColor = color;

}