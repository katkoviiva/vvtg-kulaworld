uniform sampler2D tex;

uniform vec3 lol;

void main() {
	gl_FragColor = texture2D(tex,gl_TexCoord[0].st);// vec4(0.4,0.4,0.8,1.0);
	gl_FragColor.x *= 0.5 * (1.0 + sin(1.0*lol));
}
