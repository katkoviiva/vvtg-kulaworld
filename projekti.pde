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

PImage texmap;

float lasttime = 0;

PImage grass, pltex;
ArrayList<GameObject> coins = new ArrayList<GameObject>();

PFont font;

float mapx, mapy, mapz;

int playertime;

PImage morko;
// Ghost gost;
class Ghost {
	PVector pos = new PVector(-1, 0, 1);
	PVector up = new PVector(-1, 0, 0);
	void draw() {
		PGraphics pa = g;
		pa.pushMatrix();
		pa.translate(pos.x, pos.y, pos.z);
		PVector cam = PVector.add(PVector.sub(player.pos, PVector.mult(player.dir, 4)), PVector.mult(player.up, 2));
		PVector dir = PVector.sub(cam, pos);
		dir.normalize();
		PVector x = up.cross(dir);
		PMatrix3D r = new PMatrix3D(
			x.x, up.x, dir.x, 0,
			x.y, up.y, dir.y, 0,
			x.z, up.z, dir.z, 0,
			  0,    0,     0, 1);
		pa.applyMatrix(r);
// 		pa.applyMatrix(rotstate);
		
		noStroke();
		fill(255);
// 		pushMatrix();
// 		translate(pos.x, pos.y, pos.z);
// 		rotateY(millis()/1000.0);
		textureMode(NORMALIZED);
		beginShape();
		texture(morko);
		vertex(-0.5, -0.5, 0,  0, 1);
		vertex(0.5, -0.5, 0,  1, 1);
		vertex(0.5, 0.5, 0,  1, 0);
		vertex(-0.5, 0.5, 0,  0, 0);
		endShape();
		popMatrix();
	}
}
Ghost2 gost;
class Ghost2 extends GameObject {
	public Ghost2(PVector p, PVector d, PVector u, World w, PApplet pa, OBJModel model) {
		super(p, d, u, w, pa, model);
	}
	void update(float dt) {
		rot(dt);
		PVector cam = PVector.add(PVector.sub(player.pos, PVector.mult(player.dir, 4)), PVector.mult(player.up, 2));
		PVector dirr = PVector.sub(cam, pos);
		dirr.normalize();
		dir = PVector.sub(new PVector(), dirr);
	}
	void render(PGraphics g, PImage tex) {
		update(0);
		beginShape();
		texture(morko);
		vertex(-0.5, -0.5, 0,  0, 1);
		vertex(0.5, -0.5, 0,  1, 1);
		vertex(0.5, 0.5, 0,  1, 0);
		vertex(-0.5, 0.5, 0,  0, 0);
		endShape();
	}
}

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
	grass = loadImage("Seamless_grass_texture_by_hhh316.jpeg");
	pltex = loadImage("Awesome3.png");
	morko = loadImage("ghost.png");
	gost = new Ghost2(new PVector(-1, 0, 1), new PVector(0, 0, 1), new PVector(-1, 0, 0), world, this, null);
	world.boxTex(grass);
	OBJModel mdl = new OBJModel(this, "kolikko.obj", "absolute" /* relative */, PApplet.POLYGON);
	ArrayList<PVector> endpts = world.endpoints();
	for (int i = 0; i < endpts.size(); i += 2) {
		PVector pos = endpts.get(i), up = endpts.get(i + 1), dir = new PVector(1, 0, 0);
		if (up.x != 0) dir = new PVector(0, 1, 0);
		coins.add(new Coin(pos, dir, up, world, this, mdl));
		//, endpts.get(i), endpts.get(i+1)));
	}
		//GameObject(PApplet pap, OBJModel mdl, PVector p, PVector u) {
		//pa = pap;	GameObject(PVector p, PVector d, PVector u, World w, PApplet pa, OBJModel model) {
			
	font = createFont("Courier", 20, true);
pg = createGraphics(width/4, height/4, P3D);
 // 	println(PFont.list());
}
PMatrix3D rotmat(float a, float x, float y, float z) {
	PMatrix3D mat = new PMatrix3D();
	mat.rotate(a, x, y, z);
	return mat;
}
void keyPressed () {
	player.pressKey(key);
	if (key == 's') camera.preApply(rotmat(-PI/40, 1, 0, 0));
	if (key == 'w') camera.preApply(rotmat(PI/40, 1, 0, 0));
	if (key == 'a') camera.preApply(rotmat(-PI/40, 0, 1, 0));
	if (key == 'd') camera.preApply(rotmat(PI/40, 0, 1, 0));
	if (key == 'q') camera.preApply(rotmat(-PI/40, 0, 0, 1));
	if (key == 'e') camera.preApply(rotmat(PI/40, 0, 0, 1));
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
	float dt = (millis() - lasttime) / 1000.0;
	background(0);
	
	for (GameObject c: coins) {
		c.update(dt);
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
	if (lasttime != 0) player.update(dt);
	lasttime = millis();
}
PMatrix3D mapState = new PMatrix3D();
PGraphics pg;
void render() {
	textureMode(NORMALIZED);
	player.apply(this);
	scale(100);
	background(0);
	ambientLight(20, 20, 20);
	lightFalloff(0.1, 0.0, 0.0002);
	PVector lightpos = PVector.add(player.pos, PVector.mult(player.dir, 0.51));
	spotLight(255, 255, 255, lightpos.x, lightpos.y, lightpos.z, player.dir.x, player.dir.y, player.dir.z, PI/4, 10);
	fill(255, 255, 255, 255);
	player.draw(g, pltex);
	gost.draw(g, null);
	
	noStroke();
	world.draw(g);
	
	for (GameObject obj: coins) { obj.draw(g, null); }
	
	if (animobj != null) {
		float time = (millis()-animstart)/1000.0;
		PVector pp = animobj.pos;
		animobj.pos = PVector.add(pp, PVector.mult(animobj.up, 2*time));
		animobj.draw(g, null); // pyörittele nopeammin!
		animobj.pos = pp;
		if (time >= 2) animobj = null;
	}
	
	pg.beginDraw();
	pg.background(0);
	pg.stroke(255);
	pg.noStroke();
	pg.fill(255);
	pg.translate(pg.width/2,pg.height/2, 0);
	pg.scale(5);
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

	resetMatrix();
	noLights();
	
	hint(DISABLE_DEPTH_TEST);
	textureMode(NORMALIZED);
	resetMatrix();
	translate(50,10, -200);
	stroke(255);
	fill(255,255,255,10);
	beginShape(QUADS);
	texture(pg);
	int w=100;
	int h=100;
	vertex(0, 0, 0,  0, 0);
	vertex(w, 0, 0,  1, 0);
	vertex(w, h, 0, 1, 1);
	vertex(0, h, 0,  0, 1);
	endShape(); 
	hint(ENABLE_DEPTH_TEST);

	textFont(font);
	textMode(SCREEN);
	fill(255);
	text("Coins: " + coins.size(), 10, 20);
	text("fps: " + frameRate, 10, 40);
	text("pos: (" + player.pos.x + ", " + player.pos.y + ", " + player.pos.z + "), sz=" + world.size, 10, 60);
	text("time: " + (playertime != 0 ? playertime/1000.0 : millis() / 1000.0) + ", steps: " + abs(player.steps), 10, 80);
	
}
