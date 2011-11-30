/*
 * etäisyydet tilejen välillä aina ykkösiä
 * tilen säde siis 0.5
 * kokonaislukukoordinaatti aina tilen keskellä
 * pelipallon säde 0.5
 * pelipallo säteen etäisyydellä tilen pinnasta
 * */

import java.util.*;
import processing.opengl.*;
import saito.objloader.*;

final int wsize = 4;
World world;
Player player;
// TexCube tcube;

PImage texmap;

int sDetail = 35;  // Sphere detail setting

float[] cx, cz, sphereX, sphereY, sphereZ;
float sinLUT[];
float cosLUT[];
float SINCOS_PRECISION = 0.5;
int SINCOS_LENGTH = int(360.0 / SINCOS_PRECISION);
float lasttime = 0;

PImage grass;
GameObject coin;

PFont font;

void setup() {
	size(800, 600, OPENGL);
	randomSeed(0);
// 	tcube = new TexCube(new PlasmaTex(new PImage(64, 64)));
	world = new World(this, wsize);
	player = new Player(
	new PVector(-1, 0, 0), 
	new PVector(0, 0, 1), 1,
	new PVector(-1, 0, 0),
	world);
	
	texmap = loadImage("world32k.jpg");    
	initializeSphere(sDetail);
	grass = loadImage("Seamless_grass_texture_by_hhh316.jpeg");
	world.boxTex(grass);
	OBJModel mdl = new OBJModel(this, "kolikko.obj", "absolute" /* relative */, PApplet.POLYGON);
	coin = new GameObject(this, mdl, new PVector(-1,0,3));
	font = createFont("Courier", 20, true);
	println(PFont.list());
}
void keyPressed () {
	player.pressKey(key);
}

void keyReleased () {
}
void mouseDragged() {
/*	PVector mouseDiff = PVector.sub(new PVector(mouseX, mouseY), new PVector(pmouseX, pmouseY));
	cam.phi += 2 * PI * mouseDiff.x / width;
	cam.theta -= PI * mouseDiff.y / height;*/
	//cam.theta = constrain(cam.theta - PI * mouseDiff.y / height, -PI / 2, PI / 16);
}
void draw() {
// 	tcube.update();
	background(0);
	
	if (lasttime != 0) player.update((millis() - lasttime) / 1000.0);
	lasttime = millis();

// scale(100);	pointLight(255, 255, 255, player.pos.x-player.up.x, player.pos.y-player.up.y, player.pos.z-player.up.z);
	player.apply(this);
	textureMode(NORMALIZED);
// 	background(world.hasBlk(PVector.add(player.pos, PVector.mult(player.up, -1))) ? 0 : color(0, 0, 255));
// 	background(world.hasBlk(PVector.add(player.pos, PVector.mult(player.dir, 0.5 + 0.001))) ? 0 : color(0, 0, 255));

	scale(100);
	
	ambientLight(30, 30, 30);
	ambientLight(255,255,255);
	

	noStroke();
	fill(100, 100, 100, 100);
	stroke(100);
	player.draw(this);
	
	stroke(255);noStroke();
	world.draw(this);
	coin.draw();

	textFont(font);

	textMode(SCREEN);
	text("Hei moi tättädää", 10, 20);
}


// tekstuuroidun kuution piirto
class TexCube2 {
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
	
	TimeTexture tex;
	
	public TexCube2(TimeTexture t) {
		tex = t;
	}
	public void update() {
		tex.update();
	}
	public void draw(float scale) {
		scale(scale);
		for (int i = 0; i < 6; i++) square(i);
		scale(1/scale);
	}
	// piirrä yksi tahko
	private void square(int i) {
		beginShape();
		tex.apply();
		//noTexture();
		// tekstuurikoordinaatit (normalisoituina)
		int[] uv = {1, 0,  0, 0,  0, 1,  1, 1};
		for (int j = 0; j < 4; j++) {
			int a = indices[4 * i + j];
			vertex(vertices[3 * a], vertices[3 * a + 1], vertices[3 * a + 2], uv[2*j], uv[2*j+1]);
			//vertex(vertices[3 * a], vertices[3 * a + 1], vertices[3 * a + 2]);
		}
		endShape();
	}
}

// jollain lailla ajan mukana muuttuva tekstuuri
abstract class TimeTexture {
	PImage tex;
	protected TimeTexture(PImage t) {
		tex = t;
	}
	// päivitä pikselit nykyhetken mukaan
	public void update() {
		float time = millis() / 1000.0;
		tex.loadPixels();
		int pi = 0;
		for (int y = 0; y < tex.height; y++) {
			for (int x = 0; x < tex.width; x++) {
				tex.pixels[pi++] = at((float)x / tex.width, (float)y / tex.height, time);
			}
		}
		tex.updatePixels();
	}
	public void apply() {
		texture(tex);
	}
	abstract int at(float x, float y, float time);
}

// geneerinen plasmaefekti
class PlasmaTex extends TimeTexture {
	int[] colormap = new int[256];
	PlasmaTex(PImage t) {
		super(t);
		int max = 4 * 63;
		// paletti 0-r-g-b-0
		for (int i = 0; i < 64; i++) {
			int j = 4 * i;
			colormap[      i] = color(j, 0, 0);
			colormap[ 64 + i] = color(max-j, j, 0);
			colormap[128 + i] = color(0, max-j, j);
			colormap[192 + i] = color(0, 0, max-j);
		}
	}
	// kivan värinen piste hatusta heitetyillä ja nätiksi iteroiduilla kaavoilla
	int at(float x, float y, float time) {
		float a = (1 + cos(x * 2 + time * 3)) / 2;
		float b = (1 + sin(y * 15 * cos(0.5 * x * sin(time) + 0.2 * time) + time * 3)) / 2;
		return colormap[255 & (int)(255 * (a + b + time))];
	}
}

// x xor y, plus vähän ajan vaikutusta.
class XorTex extends TimeTexture {
	public XorTex(PImage t) {
		super(t);
	}
	int at(float x, float y, float time) {
		int xx = int(255 * (x * (0.5 + 0.5 * sin(time)))) & 255;
		int yy = int(255 * (y + time)) & 255;
		int c = xx ^ yy;
		return color(c, c, c);
	}
}





void initializeSphere(int res)
{
  sinLUT = new float[SINCOS_LENGTH];
  cosLUT = new float[SINCOS_LENGTH];

  for (int i = 0; i < SINCOS_LENGTH; i++) {
    sinLUT[i] = (float) Math.sin(i * DEG_TO_RAD * SINCOS_PRECISION);
    cosLUT[i] = (float) Math.cos(i * DEG_TO_RAD * SINCOS_PRECISION);
  }

  float delta = (float)SINCOS_LENGTH/res;
  float[] cx = new float[res];
  float[] cz = new float[res];
  
  // Calc unit circle in XZ plane
  for (int i = 0; i < res; i++) {
    cx[i] = -cosLUT[(int) (i*delta) % SINCOS_LENGTH];
    cz[i] = sinLUT[(int) (i*delta) % SINCOS_LENGTH];
  }
  
  // Computing vertexlist vertexlist starts at south pole
  int vertCount = res * (res-1) + 2;
  int currVert = 0;
  
  // Re-init arrays to store vertices
  sphereX = new float[vertCount];
  sphereY = new float[vertCount];
  sphereZ = new float[vertCount];
  float angle_step = (SINCOS_LENGTH*0.5f)/res;
  float angle = angle_step;
  
  // Step along Y axis
  for (int i = 1; i < res; i++) {
    float curradius = sinLUT[(int) angle % SINCOS_LENGTH];
    float currY = -cosLUT[(int) angle % SINCOS_LENGTH];
    for (int j = 0; j < res; j++) {
      sphereX[currVert] = cx[j] * curradius;
      sphereY[currVert] = currY;
      sphereZ[currVert++] = cz[j] * curradius;
    }
    angle += angle_step;
  }
  sDetail = res;
}

// Generic routine to draw textured sphere
void texturedSphere(float r, PImage t) 
{
  int v1,v11,v2;
//   r=mouseY/10.0;;
  beginShape(TRIANGLE_STRIP);
  texture(t);
  float iu=(float)(t.width-1)/(sDetail);
  float iv=(float)(t.height-1)/(sDetail);
  float u=0,v=iv;
  for (int i = 0; i < sDetail; i++) {
    vertex(0, -r, 0,u,0);
    vertex(sphereX[i]*r, sphereY[i]*r, sphereZ[i]*r, u, v);
    u+=iu;
  }
  vertex(0, -r, 0,u,0);
  vertex(sphereX[0]*r, sphereY[0]*r, sphereZ[0]*r, u, v);
  endShape();   
  
  // Middle rings
  int voff = 0;
  for(int i = 2; i < sDetail; i++) {
    v1=v11=voff;
    voff += sDetail;
    v2=voff;
    u=0;
    beginShape(TRIANGLE_STRIP);
    texture(t);
    for (int j = 0; j < sDetail; j++) {
      vertex(sphereX[v1]*r, sphereY[v1]*r, sphereZ[v1++]*r, u, v);
      vertex(sphereX[v2]*r, sphereY[v2]*r, sphereZ[v2++]*r, u, v+iv);
      u+=iu;
    }
  
    // Close each ring
    v1=v11;
    v2=voff;
    vertex(sphereX[v1]*r, sphereY[v1]*r, sphereZ[v1]*r, u, v);
    vertex(sphereX[v2]*r, sphereY[v2]*r, sphereZ[v2]*r, u, v+iv);
    endShape();
    v+=iv;
  }
  u=0;
  
  // Add the northern cap
  beginShape(TRIANGLE_STRIP);
  texture(t);
  for (int i = 0; i < sDetail; i++) {
    v2 = voff + i;
    vertex(sphereX[v2]*r, sphereY[v2]*r, sphereZ[v2]*r, u, v);
    vertex(0, r, 0,u,v+iv);    
    u+=iu;
  }
  vertex(sphereX[voff]*r, sphereY[voff]*r, sphereZ[voff]*r, u, v);
  endShape();
  
}
