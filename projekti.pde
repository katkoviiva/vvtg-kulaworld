/*
 * etäisyydet tilejen välillä aina ykkösiä
 * tilen säde siis 0.5
 * kokonaislukukoordinaatti aina tilen keskellä
 * pelipallon säde 0.5
 * pelipallo säteen etäisyydellä tilen pinnasta
 * */

import java.util.*;

import processing.opengl.*;
int wsize = 3;
World world;
Player player = new Player(
	new PVector(-1, 0, 0), 
	new PVector(0, 0, 1), 1,
	new PVector(-1, 0, 0)
);
TexCube tcube = new TexCube(new PlasmaTex(new PImage(64, 64)));
class FlyCam 
{
  FlyCam ()
  {
      view = new PMatrix3D(1, 0, 0, 0,
                           0, 1, 0, 0,
                           0, 0, 1, 0,
                           0, 0, 0, 1);
      pos           = new PVector(0,0,0);
      move_forward  = false;
      move_backward = false;
      move_left     = false;
      move_right    = false;
  }
  
  // Update camera position using current motion state.
  void update ()
  {
    float dx = 0.0;
    float dz = 0.0;
    float spd = 0.1;
    dx += move_left     ?  1.0 : 0.0;
    dx += move_right    ? -1.0 : 0.0;
    dz += move_forward  ?  1.0 : 0.0;
    dz += move_backward ? -1.0 : 0.0;
    // Viewing directions are in the view matrix rows as viewer X,Y,Z
    pos.x -= spd * (dx * view.m00 + dz * view.m20);
    pos.y -= spd * (dx * view.m01 + dz * view.m21);
    pos.z -= spd * (dx * view.m02 + dz * view.m22);    
  }
  
  // Apply viewing matrix corresponding to camera.
  void apply ()
  {
    // Form viewing matrix from angles and position.
    view.set(1,0,0,0,
             0,1,0,0,
             0,0,1,0,
             0,0,0,1);
    view.rotateX (theta);
    view.rotateY (phi);    
    view.translate(-pos.x, -pos.y, -pos.z);
    applyMatrix (view);
  }
  
  boolean move_forward;
  boolean move_backward;
  boolean move_left;
  boolean move_right;
  
  PVector  pos;   // Viewer position
  float     phi;   // Horizontal angle
  float     theta; // Vertical angle
  PMatrix3D view;  // Viewing matrix
};

void keyPressed ()
{
   if (key == 'a') cam.move_left     = true;
   if (key == 'd') cam.move_right    = true;
   if (key == 'w') cam.move_forward  = true;
   if (key == 's') cam.move_backward = true;
   player.doKbd(key, true);
   player.pressKey(key);
}

void keyReleased ()
{
   if (key == 'a') cam.move_left     = false;
   if (key == 'd') cam.move_right    = false;
   if (key == 'w') cam.move_forward  = false;
   if (key == 's') cam.move_backward = false;
   player.doKbd(key, false);
}
void mouseDragged() {
	PVector mouseDiff = PVector.sub(new PVector(mouseX, mouseY), new PVector(pmouseX, pmouseY));
	cam.phi += 2 * PI * mouseDiff.x / width;
	cam.theta -= PI * mouseDiff.y / height;
	//cam.theta = constrain(cam.theta - PI * mouseDiff.y / height, -PI / 2, PI / 16);
}
FlyCam cam = new FlyCam();






PImage bg;
PImage texmap;

int sDetail = 35;  // Sphere detail setting
float rotationX = 0;
float rotationY = 0;
float velocityX = 0;
float velocityY = 0;
float globeRadius = 450;
float pushBack = 0;

float[] cx, cz, sphereX, sphereY, sphereZ;
float sinLUT[];
float cosLUT[];
float SINCOS_PRECISION = 0.5;
int SINCOS_LENGTH = int(360.0 / SINCOS_PRECISION);








void setup() {
	size(800, 600, OPENGL);
	cam.pos.set(0, 0, 0);
	randomSeed(0);
	world=new World(wsize);
	//cam.phi = -PI/4;
	//cam.theta=PI/4;
	
	texmap = loadImage("/home/sooda/world32k.jpg");    
  initializeSphere(sDetail);
	
	
	
}
float lasttime = 0;
void draw() {
	cam.update();
	
	tcube.update();
	textureMode(NORMALIZED);
	lights();
	background(world.hasBlk(PVector.add(player.pos, PVector.mult(player.up, -1))) ? 0 : color(0, 0, 255));
// 	background(world.hasBlk(PVector.add(player.pos, PVector.mult(player.dir, 0.5 + 0.001))) ? 0 : color(0, 0, 255));
	
	noStroke();
	stroke(255);
	
	beginCamera();
	resetMatrix();
// 	scale(1, -1, 1);
	endCamera();
	
// 	resetMatrix();
// 	scale(1, -1, 1);
// 	println(tan(PI*60.0/360.0));
// 	perspective(PI/3.0, width/height, cameraZ/10.0, cameraZ*10.0);
// 	perspective(PI/3.0, width/height, 1, cameraZ*10.0);
	//frustum(-width/2, width/2, 0, height, -100, 100);
	  // Make sure that the camera matrix is identity. Not needed.
  //beginCamera ();
  //resetMatrix();
  //scale(1, -1, 1);
  //endCamera ();
  //resetMatrix();
  // Flip y-axis up. Using a left handed coordinate system is insane.waa
  //scale(1, -1, 1);
  // Setup a point light a the viewer's position.
  // Set viewer position (= Camera matrix)  
	//cam.apply ();
	scale(100);
	player.apply();
	scale(100);
// 	translate(0, 0, -5);
	world.draw();
	if (lasttime != 0) player.update(millis() - lasttime);
	lasttime = millis();
	player.draw();

	float pos = 0.5 * (1 + sin(millis() / 1000.0));
	translate(-1, 0, pos);
	stroke(255);
	noStroke();
	fill(0, 255, 0);
	
// 	sphere(0.5);
	rotateY(2*PI*pos/(2*PI*0.5));
	stroke(255);
}

class Kbd {
	boolean[] buttons = new boolean[256];
}

class Player {
	PVector pos, dir, up; // maailmakoordinaatistossa
	float spd;
	Kbd kbd = new Kbd();
	boolean rotated = false;
	boolean rotating = false;
	
	PVector origup, origdir, origpos;
	float animtime;
	
	float turnang;
	boolean turning = false;
	
	boolean hitrot;
	
	boolean walking = false;
	LinkedList<Integer> keyHistory = new LinkedList<Integer>();
	
	abstract class Animation {
		PVector opos, odir, oup;
		float time;
		abstract void animate(/*Player player*/float time);
		void start() {
			opos = PVector.mult(pos, 1);
			odir = PVector.mult(dir, 1);
			oup = PVector.mult(up, 1);
			time = 0;
		}
		boolean run(float dt) {
			time += dt;
			if (time > 1) time = 1;
			animate(time);
			return time != 1;
		}
	}
	class Walk extends Animation {
		void animate(float time) {
			
		}
	}
	class Rotation extends Animation {
		void animate(float time) {
		}
	}
	
	Animation animation = null;
	
	Player(PVector p, PVector d, float s, PVector u) {
		pos = p;
		dir = d;
		spd = s;
		up = u;
	}
	void apply() {
		PVector e = PVector.sub(pos, PVector.mult(dir, 4));
		e.add(PVector.mult(up, 2));
		int s=100;
		camera(s*e.x, s*e.y, s*e.z, s*pos.x, s*pos.y, s*pos.z,- up.x, -up.y, -up.z);
// 		camera(-100, -100, -100,  0, 0, 0,  0, 1, 0);
		//camera(-100, -100, -100,  0, 0, 0,  0, 1, 0);
	}
	void update(float dt) {
		dt /= 1000;
		if (animation != null) {
			if (animation.run(dt)) {
				animation = null;
			}
		}
		if (walking) {
			animtime += dt / 0.5 * spd;
			if (animtime >= 1) {
				animtime = 1;
				walking = false;
			}
			pos = PVector.add(origpos, PVector.mult(dir, animtime));
		} else if (hitrot) {
			animtime += dt / 1 * spd;
			if (animtime >= 1) {
				rotating = false;
				animtime = 1;
			}
			PVector axis = origup.cross(origdir);
			axis.mult(-1);
			PMatrix3D rotmat = new PMatrix3D();
			rotmat.rotate(animtime * PI/2, axis.x, axis.y, axis.z);
			dir = rotmat.mult(origdir, null);
			up = rotmat.mult(origup, null);
			/*PVector diff = PVector.mult(PVector.add(up, dir), animtime * 0.5);
			pos = PVector.add(origpos, diff);*/
			// TODO: pyöristä täällä lopuksi (animtime==1) nuo niin ettei mee tippaakaan vinoon
			println(dir.mag());
			println(up.mag());
			println(pos);
			println("");
		} else if (rotating) {
			// TODO: animaattoriluokkia jotka varastoi old* ja .apply(Player p, float time)
			animtime += dt / 1 * spd;
			if (animtime >= 1) {
				rotating = false;
				animtime = 1;
	/*			
				PVector axis = origup.cross(origdir);
				PMatrix3D rotmat = new PMatrix3D();
				rotmat.rotate(animtime * PI/2, axis.x, axis.y, axis.z);
				dir = rotmat.mult(origdir, null);
				up = rotmat.mult(origup, null);
				pos = origpos;
				// EI NÄIN vaan etsi pinnan koordinaatti tasan ja siitä ylös
				PVector diff = PVector.mult(PVector.add(up, dir), 0.5);
				pos = PVector.add(origpos, diff);
*/				
				// pinnan normaali:
				// - kuution jonka pääl mennään saa suoraan koordinaateist
				// - katotaan mil puolel kuutiota koordinaatit on niin saadaan mikä tahko on kyseessä
				// - yhen tilen tahkon normaali on tasan koordinaattiakselin suuntainen; millä puolella kuutiota ollaan?
				// - jotenki sijainnin erotus ja siit maksimiakseli ni sen suuntaan ykkösen verran on normi

				// todo: fiksaa paikka iha oikein
				// tms: pos.add(PVector.mult(up, dt));
				//return;

			}
			PVector axis = origup.cross(origdir);
			if (spd < 0) axis.mult(-1);
			PMatrix3D rotmat = new PMatrix3D();
			rotmat.rotate(animtime * PI/2, axis.x, axis.y, axis.z);
			dir = rotmat.mult(origdir, null);
			up = rotmat.mult(origup, null);
			PVector diff = PVector.mult(PVector.add(up, dir), animtime);
			pos = PVector.add(origpos, diff);
			println(dir.mag());
			println(up.mag());
			println(pos);
			println("");
			println("rotrot");
		} else if (turning) {
			animtime += dt / 0.25;
			if (animtime >= 1) {
				turning = false;
				animtime = 1;
			}
			dir = origdir;
			rot(animtime * turnang);
		} else {
			if (!keyHistory.isEmpty()) {
				processKey(keyHistory.removeFirst());
			}
			//keyboard(dt);
			//hitcheck();
			//dropcheck(dt);
		}
	}
	boolean hitCheck(PVector p) {
		if (world.hasBlk(p)) {
			println("hit");
			animtime = 0;
			origup = up;
			origdir = dir;
			origpos = pos;
			hitrot = true;
			return true;
		}
		return false;
	}
	
	void pressKey(char key) {
		keyHistory.addLast((int)key);
	}
	void processKey(int key) {
		if (key == 'i') walk(1);
		if (key == 'k') walk(-1);
		if (key == 'j') turn(PI/2/*2 * dt*/); //rot(1 * dt);
		if (key == 'l') turn(-PI/2/*-2 * dt*/);//rot(-1 * dt);
	}
	
	void keyboard(float dt) {
	}
	
	void walk(int where) {
		PVector dest = PVector.add(pos, PVector.mult(dir, where));
		if (hitCheck(dest)) return;
		if (dropCheck(dest)) return;
		walking = true;
		origpos = pos;
		animtime = 0;
	}
	
	boolean dropCheck(PVector p) {
		// pyörii reunalta yli:
		// pelipallon keskikohta reunan yli.
		// laatikon keskipiste kokonaisluvussa
		// putoaa kun alla ei ole enää kalikkaa
		// pyöri 90 astetta menosuuntaan youknowhow (animoi!) eli päivitä suunta ja up
		// MUTTA suunnan pitäs mennä sen alla olevan kalikan pinnan suuntaisesti mikä tapahtuu vaan 90 asteen kävelemises
		// eli up on pinnan normaali.
		// nyt alapuolel on palikka; nouse up-vektoria päin abt pinnan etäisyydelle ja siis reunalle
		
		// -- PURKKA
		// kuljetaan toistaiseksi vain kohtisuoraan reunoja päin
		if (!rotated && !world.hasBlk(PVector.add(p, PVector.mult(up, -1)))) {
			println("drop");
// 			rotated=true;
			rotating = true;
			animtime = 0;
			origup = up;
			origdir = dir;
			origpos = pos;
			return true;
		}
		return false;
	}
	
	void doKbd(char key, boolean state) {
		kbd.buttons[key] = state;
	}
	
	void rot(float ang) {
		PMatrix3D rotmat = new PMatrix3D();
		rotmat.rotate(-ang, up.x, up.y, up.z);
		dir = rotmat.mult(dir, null);
	}
	
	void turn(float ang) {
		if (rotating || turning) return;
		turning = true;
		origdir = dir;
		turnang = ang;
		animtime = 0;
	}
	void draw() {
		pushMatrix();
		translate(pos.x, pos.y, pos.z);
 		textureMode(IMAGE);  
 		texturedSphere(0.5, texmap);
		fill(100, 100, 100, 200);
// 		tcube.draw(0.5);
		popMatrix();
	}
}

class World {
	int size, size3;
	int[] map;
	//int space=2;
	World(int sz) {
		size = sz;
		size3 = sz * sz * sz;
		map = new int[size3];
		generate();

	}
	boolean hasBlk(PVector point) {
		int x = round(point.x); // round
		int y = round(point.y);
		int z = round(point.z);
		//println("has? " + point.x + " " + point.y + " " + point.z);
		return x >= 0 && y >= 0 && z >= 0 
			&& x < size && y < size && z < size 
			&& map[at(x, y, z)] != 0;
	}
	// prim's algorithm
	void generate() {
		//map=null;
		//map[0]=0;// rivi 146
		int space = 5; // ei mielellään 0.
		// sz^3 pisteitä, joiden välillä space tyhjää (tyhjä 0: kuutio)
		// eli (sz+(sz-1)*space)^3 tileä
		// visited ~ V_new
		
		boolean[] visited = new boolean[size3]; // indeksoi tileidx:llä ("pointteri")
		int[] visitorder = new int[size3]; // indeksoi järjestysnumerolla
		
		int count = 1;
		visitorder[0] = 0;
		visited[0] = true;
		int newsz = size + (size - 1) * space;
		int newsz3 = newsz * newsz * newsz;
		
		map = new int[newsz3];
		map[0] = color(255,255,255);
		
		while (count < size3) {
			//println("\nDoing: " + count);
			//print("visited:");
			//for (int i = 0; i < count; i++) print(" " + visitorder[i]);
			//println("");
			// todo: reunimmaiset tilet muistissa. muista nopeasti sellaiset joista pääsee jo joka reunalle
			// arvo tiili reunalta
			// arvo sille suunta
			// visitoi se.
			int monesko;
			do {
				monesko = (int)(random(0, count)); // monesko jo visitoitu leviää.
				//println("guess #" + monesko + " = " + visitorder[monesko]);
			} while (full(visited, visitorder[monesko]));
			int idx = visitorder[monesko];
			int z = idx / (size * size), y = idx / size % size, x = idx % size;
			//println("idx: " + idx + " at " + x + ", " + y + ", " + z);
			
			// joku vierestä
			int[] dir = getadj(x, y, z, visited);
			//println("dir: " + dir[0] + ", " + dir[1] + ", " + dir[2]);
			
			int[] newpos = {x+dir[0], y+dir[1], z+dir[2]};
			int newidx = at(newpos[0], newpos[1], newpos[2]);
			//println("newidx: " + newidx + " at " + newpos[0] + ", " + newpos[1] + ", " + newpos[2]);
			
			// idx==u, newidx==v
			visitorder[count] = newidx;
			visited[newidx] = true;
			
			int nx = newpos[0], ny = newpos[1], nz = newpos[2];
			map[at(nx*(space+1), ny*(space+1), nz*(space+1), newsz)] = color(255, 0, 0);
			
			int i=x*(space+1),j=y*(space+1),k=z*(space+1);
			for (int a = 0; a < space; a++) {
				i += dir[0];
				j += dir[1];
				k += dir[2];
				map[at(i, j, k, newsz)] = color(1, (int)((float)count / size3 * 255), (int)((float)k/newsz*255));
			}
			count++;
		}
		
		size = newsz;
		size3 = newsz3;
	}
	boolean full(boolean[] visited, int i) {
		//println("full? " + i + " " + (i % size) + " " + (i / size) % size + " " + (i / (size*size)));
		return full(visited, i % size, i / size % size, i / (size * size));
	}
	// full == tästä ei pääse enää mihinkään uuteen paikkaan
	boolean full(boolean[] visited, int x, int y, int z) {
		return (x == 0 ? true : visited[at(x-1, y, z)])
			&& (x == size-1 ? true : visited[at(x+1, y, z)])
			&& (y == 0 ? true : visited[at(x, y-1, z)])
			&& (y == size-1 ? true : visited[at(x, y+1, z)])
			&& (z == 0 ? true : visited[at(x, y, z-1)])
			&& (z == size-1 ? true : visited[at(x, y, z+1)]);
	}
	int at(int x, int y, int z) {
		return at(x, y, z, size);
	}
	int at(int x, int y, int z, int size) {
		return size * (size * z + y) + x;
	}
	int[] getadj(int x, int y, int z, boolean[] visited) {
		// -x, x, -y, y, -z, z
		int[][] dirs = {
			{-1, 0, 0},
			{1, 0, 0},
			{0, -1, 0},
			{0, 1, 0},
			{0, 0, -1},
			{0, 0, 1}};
		int i;
		boolean ok=true;
		do {
			i = int(random(0, 6));
			ok=true;
			//println("getadj: " + x + ", " + y + ", " + z + " :: " + i);
			if (x == 0 && i == 0) ok=false;
			if (y == 0 && i == 2) ok=false;
			if (z == 0 && i == 4) ok=false;
			if (x == size-1 && i == 1) ok=false;
			if (y == size-1 && i == 3) ok=false;
			if (z == size-1 && i == 5) ok=false;
		} while (!ok || visited[at(x+dirs[i][0], y+dirs[i][1], z+dirs[i][2])]);
		//println("getadj: " + i);
		return dirs[i];
	}
	void randgenerate() {
		for (int i = 0; i < 50; i++) map[int(random(0, size3))] = 1;
	}
	void draw() {
		pushMatrix();
		for (int z = 0; z < size; z++) {
			for (int y = 0; y < size; y++) {
				for (int x = 0; x < size; x++) {
					dobox(x, y, z);
				}
			}
		}
		popMatrix();
	}
	void dobox(int x, int y, int z) {
		int colo = map[size * size * z + size * y + x];
		//println(colo);
		if (colo == 0) return;
		PVector bottomidx = PVector.add(player.pos, PVector.mult(player.up, -1));
		if (x == round(bottomidx.x) && y == round(bottomidx.y) && z == round(bottomidx.z)) colo = color(255, 255, 255, 100);
		pushMatrix();
		translate(x, y, z);
		colo = (colo & 0xffffff) | 0x7f000000;
		fill(colo);
		tcube.draw(0.5);
// 		box(1);
		popMatrix();
	}
}















// tekstuuroidun kuution piirto
class TexCube {
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
	
	public TexCube(TimeTexture t) {
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
		noTexture();
		// tekstuurikoordinaatit (normalisoituina)
		int[] uv = {1, 0,  0, 0,  0, 1,  1, 1};
		for (int j = 0; j < 4; j++) {
			int a = indices[4 * i + j];
			//vertex(vertices[3 * a], vertices[3 * a + 1], vertices[3 * a + 2], uv[2*j], uv[2*j+1]);
			vertex(vertices[3 * a], vertices[3 * a + 1], vertices[3 * a + 2]);
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
