// vim: ft=c

uniform float time;

vec4 effect(vec4 color, Image tex, vec2 texCoord, vec2 pixelCoord)
{
    // TODO put awesome effect here
    vec2 d = (sin(texCoord * 20 + time * 5)) / 40;
    vec4 c = texture2D(tex, texCoord + d).rgba;
    return c;
}
