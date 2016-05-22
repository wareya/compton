/*
Monitor: AOC G2460PF
settings:
gamma3
contrast 46 (fixes gamma table banding)
brightness 0
funny settings diabled
color temp: user
rgb: 50 each
*/

#version 130
#extension GL_ARB_arrays_of_arrays: enable

uniform sampler2D tex;
uniform float opacity;
uniform bool invert_color;
uniform int h;
uniform int w;

float depth = 255.0;

float dtable[4][2][2] =
float[][][](
    // 0%
    float[][](
        float[](0,0),
        float[](0,0)
    ),
    // 25%
    float[][](
        float[](0,1),
        float[](0,0)
    ),
    // 50%
    float[][](
        float[](1,0),
        float[](0,1)
    ),
    // 75%
    float[][](
        float[](1,1),
        float[](0,1)
    )
);

float dither(float c, vec2 coord, float range)
{
    int f = int(round(mod(c*range, 1)*4));
    // 0011112222333344
    ///\      /\      /\
    //0.      .5      1.
    c = floor(c*range)/range;
    if(f > 3.5) // 7/8 * 4
    {   c += 1/range; f = 0;   }
    int x = int(mod(coord.x*w, 2));
    int y = int(mod(coord.y*h, 2));
    c += dtable[f][x][y]/range;
    return c;
}

float correct(float c, vec2 coord, float topow, float black, float white, float floorrate) {
    float range = white-black;
    black = black/depth;
    white = range/depth;
    if(c<0)c=0;
    float ret = max(c*floorrate, pow(pow(c, 2.2), 1/topow));
    ret *= white;
    ret = dither(ret, coord, range);
    ret += black;
    if(ret<0)ret=0;
    return round(ret*depth)/depth;
}
void main() {
    vec2 co = gl_TexCoord[0].st;
    vec4 c = texture2D(tex, gl_TexCoord[0].st);
    int x = int(co.x*w);
    int y = int(co.y*h);
    if (invert_color)
        c = vec4(vec3(c.a, c.a, c.a) - vec3(c), c.a);
    if(c.a == 1.0)
    {
        c.r = correct(c.r, co, 2.0, 5, 240.0, 0.65);
        c.g = correct(c.g, co, 1.85, 5, 240.0, 0.55);
        c.b = correct(c.b, co, 1.7, 5, 240.0, 0.45);
    }
    
    c *= opacity;
    gl_FragColor = c;
}
