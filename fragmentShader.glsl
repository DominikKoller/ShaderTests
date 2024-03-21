in vec2 vTextureCoord;
in vec4 vColor;

uniform sampler2D uTexture;
uniform float uTime;
uniform float uProgress;
uniform int uDebug;

void main(void)
{
    vec2 uvs = vTextureCoord.xy;

    vec4 fg = texture2D(uTexture, vTextureCoord);

    fg.r = uvs.y + sin(uProgress);

    if(uDebug == 1) {
        fg.g = 1.0;
    }

    gl_FragColor = fg;

}