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
final int HITS_TILL_DEATH = 3;
World world;
Player player;

PImage texmap;

float lasttime = 0;

PImage grass;
ArrayList<GameObject> coins = new ArrayList<GameObject>();
ArrayList<GameObject> enemies = new ArrayList<GameObject>();

PFont font;

float mapx, mapy, mapz;

int playertime;

PImage morko;
Ghost gost;

PGraphics mapImage;

int hitEffectDelay = 3;
int hitTime = 3000;
int enemiesHit = 0;


class Ghost extends GameObject {
	public Ghost(PVector p, PVector d, PVector u, World w, PApplet pa, OBJModel model) {
		super(p, d, u, w, pa, model);
	}
	void update(float dt) {
		super.update(dt);
		if (animation == null) walk(1);
// 		rot(dt);
// 		PVector cam = PVector.add(PVector.sub(player.pos, PVector.mult(player.dir, 4)), PVector.mult(player.up, 2));
// 		PVector dirr = PVector.sub(cam, pos);
// 		dirr.normalize();
// 		dir = PVector.sub(new PVector(), dirr);
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
// 	randomSeed(0); // samanlainen kenttä aina

	world = new World(this, wsize);
	// pelaaja lähtee vakiopaikasta vakiosuuntaan; koska kyseessä on nurkka, siinä on aina joku palikka
	player = new Player(
		new PVector(-1, 0, 0), 
		new PVector(0, 0, 1),
		new PVector(-1, 0, 0),
		world, this, new OBJModel(this, "pampula.obj", "absolute" /* relative */, PApplet.POLYGON));
	
	texmap = loadImage("world32k.jpg");    
	grass = loadImage("Seamless_grass_texture_by_hhh316.jpeg");
	morko = loadImage("ghost.png");
	gost = new Ghost(new PVector(-1, 0, 1), new PVector(0, 0, 1), new PVector(-1, 0, 0), world, this, null);
	world.boxTex(grass);
	
	OBJModel coinmdl = new OBJModel(this, "kolikko.obj", "absolute", PApplet.POLYGON);
	
	ArrayList<PVector> endpts = world.endpoints();
	for (int i = 0; i < endpts.size(); i += 2) {
		PVector pos = endpts.get(i), up = endpts.get(i + 1), dir = new PVector(1, 0, 0);
		if (up.x != 0) dir = new PVector(0, 1, 0);
		coins.add(new Coin(pos, dir, up, world, this, coinmdl));
		Ghost g = new Ghost(pos, dir, up, world, this, null);
		g.walk(1);
		enemies.add(g);
	}
	font = createFont("Courier", 20, true);
	mapImage = createGraphics(width/4, height/4, P3D);
}

GameObject animobj = null;
int animstart;

void draw() {
	update();
	render();
}

void update() {
	float dt = (millis() - lasttime) / 1000.0;
	
	for (GameObject o: coins) {
		o.update(dt);
		if (PVector.sub(player.pos, o.pos).mag() < 0.001) {
			animobj = o;
			animstart = millis();
			coins.remove(o);
			if (coins.size() == 0) {
				playertime = millis();
				player.steps = -player.steps;
			}
			break;
		}
	}

	for (GameObject o: enemies) {
		o.update(0.1 * dt);
		if (PVector.sub(player.pos, o.pos).mag() < 0.1) {
			println("ENEMY HIT!");
			enemies.remove(o);
			hitTime = millis();
			if (++enemiesHit == HITS_TILL_DEATH) {
				exit();
			}
			break;
		}
	}

	if (lasttime != 0) player.update(dt);
	lasttime = millis();
}

void render() {
	textureMode(NORMALIZED);
	noStroke();
	renderScene();
	renderMap();
	renderText();
}

void renderScene() {
	player.apply(this); // kamera kivasti peliukkoa päin
	scale(100); // nätimpiä yksiköitä

	// väritys
	float timeSinceHit = (millis() - hitTime) / 1000.0;
	if (timeSinceHit < hitEffectDelay)
		background(255 - 255 * sin(PI/2 * timeSinceHit / hitEffectDelay), 0, 0);
	else
		background(0);
	fill(255, 255, 255, 255);
	ambientLight(20, 20, 20);
	lightFalloff(0.1, 0.0, 0.0002);
	PVector lightpos = PVector.add(player.pos, PVector.mult(player.dir, 0.51));
	spotLight(255, 255, 255, lightpos.x, lightpos.y, lightpos.z, player.dir.x, player.dir.y, player.dir.z, PI/4, 10);
	
	player.draw(g, null);
	gost.draw(g, null);
	world.draw(g);
	
	for (GameObject obj: coins) obj.draw(g, null);
	for (GameObject obj: enemies) obj.draw(g, null);
	
	if (animobj != null) {
		float time = (millis()-animstart)/1000.0;
		PVector pp = animobj.pos;
		animobj.pos = PVector.add(pp, PVector.mult(animobj.up, 2*time));
		animobj.draw(g, null); // pyörittele nopeammin!
		animobj.pos = pp;
		if (time >= 2) animobj = null;
	}
}

void renderMap() {	
	mapImage.beginDraw();
	mapImage.background(0);
	mapImage.noStroke();
	mapImage.fill(255);
	// jotenkin kivasti kuvan keskelle yms, vähän iteroitu sopivaksi
	mapImage.translate(mapImage.width/2, mapImage.height/2, 0);
	mapImage.scale(5);
	mapImage.applyMatrix(camera);
	mapImage.translate(-world.size/2, -world.size/2, -world.size/2);
	world.draw(mapImage);
	// pelaaja vilkkuu valkoisena, jäljellä olevat rahat punaisia
	if (millis() % 500 < 250) world.dobox(mapImage, player.pos, color(255, 255, 255));
	
	for (GameObject obj: coins) {
		PVector pos = PVector.sub(obj.pos, obj.up);
		if (world.hasBlk(pos)) {
			world.dobox(mapImage, pos, color(255, 0, 0));
		}
	}
	for (GameObject obj: enemies) {
		PVector pos = PVector.sub(obj.pos, obj.up);
		if (world.hasBlk(pos)) {
			world.dobox(mapImage, pos, color(255, 0, 255));
		}
	}
	mapImage.endDraw();
	
	resetMatrix();
	noLights();
	hint(DISABLE_DEPTH_TEST);
	textureMode(NORMALIZED);
	resetMatrix();
	translate(50,10, -200);
	stroke(255);
	fill(255,255,255,10);
	beginShape(QUADS);
	texture(mapImage);
	int w = 100;
	int h = 100;
	vertex(0, 0, 0,  0, 0);
	vertex(w, 0, 0,  1, 0);
	vertex(w, h, 0, 1, 1);
	vertex(0, h, 0,  0, 1);
	endShape(); 
	hint(ENABLE_DEPTH_TEST);
}

void renderText() {
	textFont(font);
	textMode(SCREEN);
	fill(255);
	int ypos = 0;
	text("Coins: " + coins.size(), 10, ypos += 20);
	text("Enemies hit: " + enemiesHit, 10, ypos += 20);
	text("fps: " + frameRate, 10, ypos += 20);
	text("pos: (" + player.pos.x + ", " + player.pos.y + ", " + player.pos.z + "), sz=" + world.size, 10, ypos += 20);
	text("time: " + (playertime != 0 ? playertime/1000.0 : millis() / 1000.0) + ", steps: " + abs(player.steps), 10, ypos += 20);
}


////********* I/O
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

void mousePressed() {
	startDrag(new PVector(mouseX, mouseY));
}
void mouseDragged() {
	drag(new PVector(mouseX, mouseY));
}




//********* hiiren pyörittely



PMatrix3D camera = new PMatrix3D();
// hiiripyörittelyolio joka muistaa hiiren aloituspaikan
MouseRotation rotation = new MouseRotation();

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



