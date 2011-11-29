import processing.core.*;
public class TexCube {
	// pisteiden paikka avaruudessa
	final float[] vertices = {
		-1, -1, -1,
		 1, -1, -1,
		 1,  1, -1,
		-1,  1, -1,
		
		-1, -1,  1,
		 1, -1,  1,
		 1,  1,  1,
		-1,  1,  1,
	};
	// neljän mittaisia indeksijonoja jotka määräävät tahkot
	final int[] indices = {
		0, 1, 2, 3,
		1, 5, 6, 2,
		5, 4, 7, 6,
		4, 0, 3, 7,
		
		4, 5, 1, 0,
		3, 2, 6, 7
	};
	
// 	TimeTexture tex;
	
// 	public TexCube(TimeTexture t) {
// 		tex = t;
// 	}
// 	public void update() {
// 		tex.update();
// 	}
	public void draw(PApplet pa, PImage tex, float scale) {
		pa.scale(scale);
		for (int i = 0; i < 6; i++) square(pa, tex, i);
		pa.scale(1/scale);
	}
	// piirrä yksi tahko
	private void square(PApplet pa, PImage tex, int i) {
		pa.beginShape();
		pa.texture(tex);
// 		tex.apply();
		//noTexture();
		// tekstuurikoordinaatit (normalisoituina)
		int[] uv = {1, 0,  0, 0,  0, 1,  1, 1};
		for (int j = 0; j < 4; j++) {
			int a = indices[4 * i + j];
			pa.vertex(vertices[3 * a], vertices[3 * a + 1], vertices[3 * a + 2], uv[2*j], uv[2*j+1]);
			//vertex(vertices[3 * a], vertices[3 * a + 1], vertices[3 * a + 2]);
		}
		pa.endShape();
	}
}
