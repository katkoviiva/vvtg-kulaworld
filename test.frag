uniform sampler2D tex;

uniform vec3 lol;

float at(vec2 asd) {
	//return (2 * (1 + sin(30.0 * asd.x + lol.x)) + (1 + cos(3.0 * cos(5.0 * asd.y + 2.0 * lol.x)))) / 3.0;
	return (1.0 + sin(asd.y * 15.0 * cos(0.5 * asd.x * sin(lol.x) + 0.2 * lol.x) + lol.x* 3.0)) / 2.0;
}

void main() {
	gl_FragColor = texture2D(tex,gl_TexCoord[0].st);// vec4(0.4,0.4,0.8,1.0);
	gl_FragColor.x *= 0.5 * (1.0 + sin(1.0*lol.x));
	gl_FragColor.y *= at(gl_TexCoord[0].st);
}
