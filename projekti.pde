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

final int wsize = 3; // 3x3 grid
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

PImage grass, pltex;
ArrayList<GameObject> coins = new ArrayList<GameObject>();

PFont font;

float mapx, mapy, mapz;

int playertime;

void setup() {
	size(800, 600, OPENGL);
	randomSeed(0);
	PGraphicsOpenGL glasdf;
// 	tcube = new TexCube(new PlasmaTex(new PImage(64, 64)));
	world = new World(this, wsize);
	player = new Player(
		new PVector(-1, 0, 0), 
		new PVector(0, 0, 1),
		new PVector(-1, 0, 0),
		world, this);
	
	texmap = loadImage("world32k.jpg");    
	initializeSphere(sDetail);
	grass = loadImage("Seamless_grass_texture_by_hhh316.jpeg");
	pltex = loadImage("Awesome2.png");
	world.boxTex(grass);
	OBJModel mdl = new OBJModel(this, "kolikko.obj", "absolute" /* relative */, PApplet.POLYGON);
	
	ArrayList<PVector> endpts = world.endpoints();
	for (int i = 0; i < endpts.size(); i += 2) {
		coins.add(new GameObject(this, mdl, endpts.get(i), endpts.get(i+1)));
	}
	
	font = createFont("Courier", 20, true);
// 	println(PFont.list());
}
PMatrix3D rotmat(float a, float x, float y, float z) {
	PMatrix3D mat = new PMatrix3D();
	mat.rotate(a, x, y, z);
	return mat;
}
void keyPressed () {
	player.pressKey(key);
	if (key == 's') camera.preApply(rotmat(-PI/40, 1, 0, 0));//mapx -= PI/40;
	if (key == 'w') camera.preApply(rotmat(PI/40, 1, 0, 0));//mapx += PI/40;
	if (key == 'a') camera.preApply(rotmat(-PI/40, 0, 1, 0));//mapy -= PI/40;
	if (key == 'd') camera.preApply(rotmat(PI/40, 0, 1, 0));//mapy += PI/40;
	if (key == 'q') camera.preApply(rotmat(-PI/40, 0, 0, 1));//mapz -= PI/40;
	if (key == 'e') camera.preApply(rotmat(PI/40, 0, 0, 1));//mapz += PI/40;
}





PMatrix3D camera = new PMatrix3D();
// hiiripyörittelyolio joka muistaa hiiren aloituspaikan
MouseRotation rotation = new MouseRotation();


void mousePressed() {
	startDrag(new PVector(mouseX, mouseY));
}
void mouseDragged() {
	drag(new PVector(mouseX, mouseY));
}

PMatrix3D lastCamera;
// klikkaa pyöritys alkamaan hiiren nykypisteestä
void startDrag(PVector mouse) {
	lastCamera = new PMatrix3D(camera);
	rotation.start(mouse);
}
// laske pyörityskulma ja -akseli, muodosta pyöritysmatriisi,
// kerro pyöritysmatriisilla sijainti joka oli kun hiiri painettiin pohjaan,
// ja sijoita tulos nykykameramatriisiksi
void drag(PVector mouse) {
	float[] rot = new float[4];
	rotation.drag(mouse, rot);
	camera.reset();
	camera.rotate(3*rot[0], rot[1], rot[2], rot[3]);
	camera.apply(lastCamera);
}

class MouseRotation {
	private PVector start, end;
	// mappaa näyttöpiste kuvittellisen pallon (oikeastaan ellipsoidin) pinnalle
	// pallo on ykkösen etäisyydellä näytöstä ja näytön kulmat "koskettavat" pintaa
	PVector findPoint(PVector screenPt) {
		// hiirellä raahaus toimii ikkunan sisällä nurkkiin saakka
		// muuten rajoitetaan arvot jos raahataan hiirtä ulkopuolelle
		float diag = dist(0, 0, width, height) / 2;
		// mappaa parametrit siten, että keskikohta on origo ja pituus 1 on ikkunan nurkassa
		float x = (constrain(screenPt.x, 0, width - 1) - width / 2) / diag;
		float y = (constrain(screenPt.y, 0, height - 1) - height / 2) / diag;
		PVector scaled = new PVector(x, y);
		float len = scaled.mag();
		assert(len <= 1);
		scaled.z = sqrt(1 - len * len); // nyt meillä on yksikkövektori
		return scaled;
	}
	
	// etsi alkupiste pinnalta ja laita talteen
	void start(PVector mouse) {
		start = findPoint(mouse);
	}
	
	// laske pyöritysakseli ja -kulma
	void drag(PVector mouse, float[] rot) {
		end = findPoint(mouse);
		// akseli on kohtisuorassa sellaisia vektoreita vasten, jotka kulkevat
		// pallon keskipisteestä alun ja lopun pintapisteille
		PVector axis = start.cross(end);
		axis.normalize(); // ellei yksikkövektori niin processingin matriisi.rotate sekoaa
		rot[0] = acos(start.dot(end));
		rot[1] = axis.x;
		rot[2] = axis.y;
		rot[3] = axis.z;
	}
}










void keyReleased () {
}

GameObject animobj = null;
int animstart;

void draw() {
	update();
	render();
}

void update() {
// 	tcube.update();
	background(0);
	
	for (GameObject c: coins) {
		if (PVector.sub(player.pos, c.pos).mag() < 0.001) {
			println("Hohoo" + PVector.sub(player.pos, c.pos).mag());
			animobj = c;
			animstart = millis();
			coins.remove(c);
			if (coins.size() == 0) {
				playertime = millis();
				player.steps = -player.steps;
			}
			break;
		}
	}
	if (lasttime != 0) player.update((millis() - lasttime) / 1000.0);
	lasttime = millis();
}
PMatrix3D mapState = new PMatrix3D();
void render() {
	textureMode(NORMALIZED);
	player.apply(this);
	scale(100);
	
// 	background(world.hasBlk(PVector.add(player.pos, PVector.mult(player.up, -1))) ? 0 : color(0, 0, 255));
// 	background(world.hasBlk(PVector.add(player.pos, PVector.mult(player.dir, 0.5 + 0.001))) ? 0 : color(0, 0, 255));
	background(0);
	
	ambientLight(70, 70, 70);
	lightFalloff(0.1, 0.0, 0.0002);
	spotLight(255, 255, 255, player.pos.x+player.dir.x, player.pos.y+player.dir.y, player.pos.z+player.dir.z, player.dir.x, player.dir.y, player.dir.z, PI/4, 10);
// 	spotLight(255, 255, 255, player.pos.x+player.up.x, player.pos.y+player.up.y, player.pos.z+player.up.z, player.dir.x, player.dir.y, player.dir.z, PI/4, 1);
// 	pointLight(255, 255, 255, player.pos.x+player.dir.x, player.pos.y+player.dir.y, player.pos.z+player.dir.z);
// 	pointLight(255, 255, 255, player.pos.x+player.up.x, player.pos.y+player.up.y, player.pos.z+player.up.z);

	stroke(100);
	fill(255, 255, 255, 255);
	player.draw(g, pltex);
	
	noStroke();
	world.draw(g);
	
	for (GameObject obj: coins) obj.draw(g, 1);
	
	if (animobj != null) {
		float time = (millis()-animstart)/1000.0;
		PVector pp = animobj.pos;
		animobj.pos = PVector.add(pp, PVector.mult(animobj.up, 2*time));
		animobj.draw(g, 3);
		animobj.pos = pp;
		if (time >= 2) animobj = null;
	}
	
	PGraphics3D juttu = new PGraphics3D();
	resetMatrix();
	noLights();
	PGraphics pg;
	pg = createGraphics(width/2, height/2, P3D);
	pg.beginDraw();
	pg.background(0);
	pg.stroke(255);
	pg.noStroke();
	pg.fill(255);
	pg.translate(pg.width/2,pg.height/2, 0);
	pg.scale(10);
	/*pg.rotateX(mapx);
	pg.rotateY(mapy);
	pg.rotateZ(mapz);//millis()/10000.0);*/
	pg.applyMatrix(/*mapState*/camera);
	pg.translate(-world.size/2, -world.size/2, -world.size/2);

	world.draw(pg);
	if (millis() % 500 < 250) world.dobox(pg, player.pos, color(255, 255, 255));
	for (GameObject obj: coins) {
		PVector pos = PVector.sub(obj.pos, obj.up);
		if (world.hasBlk(pos)) {
			world.dobox(pg, pos, color(255, 0, 0));
		}
	}
	pg.endDraw();
	
	hint(DISABLE_DEPTH_TEST);
	textureMode(IMAGE);
	resetMatrix();
	translate(50,10, -200);
	stroke(255);
	fill(255,255,255,10);
	beginShape(QUADS);
	texture(pg);
	int w=100;
	int h=100;
	vertex(0, 0, 0,  0, 0);
	vertex(w, 0, 0,  pg.width, 0);
	vertex(w, h, 0, pg.width, pg.height);
	vertex(0, h, 0,  0, pg.height);
	endShape(); 
	
	resetMatrix();
	translate(0,0,-1000);
	TexCube t = new TexCube();
	/*rotateX(millis()/1000.0);
	rotateY(millis()/200.0);
	rotateZ(millis()/500.0);*/
// 	t.draw(this, pg, 100.5f);
	resetMatrix();
	
	stroke(255);
	scale(4);
	translate(16, 16, -50);
	rotateX(mapx);
	rotateY(mapy);
	rotateZ(millis()/1000.0);
	translate(-world.size/2, -world.size/2, -world.size/2);
// 	world.draw(g);
// 	TexCube tt = new TexCube();
// 	tt.draw(g, pg, 0.5f);
	
	hint(ENABLE_DEPTH_TEST);

	textFont(font);
	textMode(SCREEN);
	fill(255);
	text("Coins: " + coins.size(), 10, 20);
	text("fps: " + frameRate, 10, 40);
	text("pos: (" + player.pos.x + ", " + player.pos.y + ", " + player.pos.z + "), sz=" + world.size, 10, 60);
	text("time: " + (playertime != 0 ? playertime/1000.0 : millis() / 1000.0) + ", steps: " + abs(player.steps), 10, 80);
	
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
