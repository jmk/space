// vim: ft=c

uniform number tint;

vec4 effect(vec4 color, Image tex, vec2 texCoord, vec2 pixelCoord)
{
    vec4 c = texture2D(tex, texCoord).rgba;
    return mix(c, vec4(1.0, 1.0, 0.0, c.a), tint);
}
