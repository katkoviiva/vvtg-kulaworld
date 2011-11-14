import processing.opengl.*;
int wsize = 4;
World world;
Player player = new Player(
	new PVector(0, 0, 0), 
	new PVector(1, 0, 0), 0,
	new PVector(0, 1, 0)
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
}

void keyReleased ()
{
   if (key == 'a') cam.move_left     = false;
   if (key == 'd') cam.move_right    = false;
   if (key == 'w') cam.move_forward  = false;
   if (key == 's') cam.move_backward = false;
}
void mouseDragged() {
	PVector mouseDiff = PVector.sub(new PVector(mouseX, mouseY), new PVector(pmouseX, pmouseY));
	cam.phi += 2 * PI * mouseDiff.x / width;
	cam.theta -= PI * mouseDiff.y / height;
	//cam.theta = constrain(cam.theta - PI * mouseDiff.y / height, -PI / 2, PI / 16);
}
FlyCam cam = new FlyCam();
void setup() {
	size(800, 600, OPENGL);
	cam.pos.set(0, 0, 0);
	randomSeed(0);
	world=new World(wsize);
	//cam.phi = -PI/4;
	//cam.theta=PI/4;
}
void draw() {
	tcube.update();
	textureMode(NORMALIZED);
	lights();
	background(0);
	noStroke();
	stroke(255);
	
	beginCamera();
	resetMatrix();
	scale(1, -1, 1);
	endCamera();
	
	resetMatrix();
	scale(1, -1, 1);
	printProjection();
	
	cam.update();
	  // Make sure that the camera matrix is identity. Not needed.
  //beginCamera ();
  //resetMatrix();
  //scale(1, -1, 1);
  //endCamera ();
  //resetMatrix();
  // Flip y-axis up. Using a left handed coordinate system is insane.waa
  //scale(1, -1, 1);
  // Setup a point light a the viewer's position.
  scale(80);
  // Set viewer position (= Camera matrix)  
  cam.apply ();
	world.draw();
}

class Player {
	PVector pos, dir, up;
	float spd;
	Player(PVector p, PVector d, float s, PVector u) {
		pos = p;
		dir = d;
		spd = s;
		up = u;
	}
	void apply() {
		
	}
	void draw() {
		pushMatrix();
		sphere(1);
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
	void generate() {
		//map=null;
		//map[0]=0;// rivi 146
		int space = 4; // ei mielellään 0.
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
			println("\nDoing: " + count);
			print("visited:");
			for (int i = 0; i < count; i++) print(" " + visitorder[i]);
			println("");
			// todo: reunimmaiset tilet muistissa. muista nopeasti sellaiset joista pääsee jo joka reunalle
			// arvo tiili reunalta
			// arvo sille suunta
			// visitoi se.
			int monesko;
			do {
				monesko = (int)(random(0, count)); // monesko jo visitoitu leviää.
				println("guess #" + monesko + " = " + visitorder[monesko]);
			} while (full(visited, visitorder[monesko]));
			int idx = visitorder[monesko];
			int z = idx / (size * size), y = idx / size % size, x = idx % size;
			println("idx: " + idx + " at " + x + ", " + y + ", " + z);
			
			// joku vierestä
			int[] dir = getadj(x, y, z, visited);
			println("dir: " + dir[0] + ", " + dir[1] + ", " + dir[2]);
			
			int[] newpos = {x+dir[0], y+dir[1], z+dir[2]};
			int newidx = at(newpos[0], newpos[1], newpos[2]);
			println("newidx: " + newidx + " at " + newpos[0] + ", " + newpos[1] + ", " + newpos[2]);
			
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
		println("getadj: " + i);
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
		pushMatrix();
		translate(x, y, z);
		fill(colo);
		tcube.draw(0.5);
		box(1);
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
