// vim: ft=c

uniform float radius;
uniform float angle;

// XXX: don't hardcode, stupid
const float size = 400.0;
const int maxSamples = 25;

#define MAX(a, b) (a > b) ? a : b;
#define MIN(a, b) (a < b) ? a : b;

vec4 effect(vec4 color, Image tex, vec2 texCoord, vec2 pixelCoord)
{
    int numSamples = MIN(int(ceil(radius)), maxSamples);

    // Compute the vector distance between samples.
    float a = radians(angle);
    float dx = cos(a) * radius / size;
    float dy = sin(a) * radius / size;
    vec2 dxy = vec2(dx, dy) / float(numSamples);

    // Average all samples in the given direction.
    vec2 p = gl_TexCoord[0].st;
    vec4 sum = vec4(0.0);
    float offset = float(numSamples) / 2.0;
    for (int i = 0; i < numSamples; ++i) {
        float dist = float(i) - offset;
        sum += texture2D(tex, p + (dxy * dist));
    }

    return sum / float(numSamples);
}
