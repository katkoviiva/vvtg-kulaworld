import java.util.*;
import processing.opengl.*;
import saito.objloader.*;

final int WSIZE = 3; // maailmassa WSIZE*WSIZE kokoinen verkko pisteitä, niiden välillä ratoja
World world;
Player player;

float lasttime = 0;


// kauanko pelattu tai kauanko peli kesti jos kaikki on kerätty
int playertime;

// esiladataan karttakuvan piirtopinta ja fontti
PGraphics mapImage;
PFont font;

// vihuun osuessa tulee parin sekunnin punainen tausta
int hitEffectDelay = 2;
int hitTime = -1000 * hitEffectDelay;
// pidetään kirjaa moneenko on osuttu, lopulta peli sulkeutuu jos osuu 
int enemiesHit = 0;
final int HITS_TILL_DEATH = 3;
ArrayList<GameObject> enemies = new ArrayList<GameObject>();

// kun kolikko kerätään niin sitä animoidaan hetki leijumaan ylöspäin
ArrayList<GameObject> coins = new ArrayList<GameObject>();
GameObject animobj = null;
int animstart;

void setup() {
	size(800, 600, OPENGL /* P3D */);
	smooth();
// 	randomSeed(0); // samanlainen kenttä aina

	world = new World(this, WSIZE, loadImage("Seamless_grass_texture_by_hhh316.jpeg"));
	// pelaaja lähtee vakiopaikasta vakiosuuntaan; koska kyseessä on nurkka, siinä on aina joku palikka
	player = new Player(
		new PVector(-1, 0, 0), 
		new PVector(0, 0, 1),
		new PVector(-1, 0, 0),
		world, this, new OBJModel(this, "pampula.obj", "absolute", PApplet.POLYGON));
	
	OBJModel coinmdl = new OBJModel(this, "kolikko.obj", "absolute", PApplet.POLYGON);
	// kolikoita jokaiseen maailman pääpisteeseen sekä jokaisesta vihu kävelemään
	PImage morko = loadImage("ghost.png");
	ArrayList<PVector> endpts = world.endpoints();
	for (int i = 0; i < endpts.size(); i += 2) {
		PVector pos = endpts.get(i), up = endpts.get(i + 1), dir = new PVector(1, 0, 0);
		if (up.x != 0) dir = new PVector(0, 1, 0);
		coins.add(new Coin(pos, dir, up, world, this, coinmdl));
		Ghost g = new Ghost(pos, dir, up, world, this, morko);
		g.walk(1);
		enemies.add(g);
	}
	// kai kaikilla courierfontti on?
	font = createFont("Courier", 20, true);
	// mielekkään kokoinen tekstuuri kun softarendaus tuntuu olevan jäätävän hidasta
	// toisaalta en löytänyt toimivaa opengl-tekstuuriinrendauskoodia tähän hätään
	mapImage = createGraphics(width/4, height/4, P3D);
}

// liikuttelu tapahtuu vain kerran per frame myös
void draw() {
	update();
	render();
}

void update() {
	float dt = (millis() - lasttime) / 1000.0;
	
	// jos kolikkoon törmää niin se leijuanimoi hetken ja katoaa
	for (GameObject o: coins) {
		o.update(dt);
		if (PVector.sub(player.pos, o.pos).mag() < 0.001) {
			animobj = o;
			animstart = millis();
			coins.remove(o);
			if (coins.size() == 0) {
				playertime = millis();
				player.steps = -player.steps; // pieni purkka ettei kävelymäärä enää etene; gameobjectissa on tarkistus
			}
			break;
		}
	}

	// vihuun törmääminen taas väläyttää taustaa punaisena ja ei saa tapahtua liian montaa kertaa
	for (GameObject o: enemies) {
		o.update(0.1 * dt);
		if (PVector.sub(player.pos, o.pos).mag() < 0.1) {
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

	// väritykset heti alkuun
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
	
	player.draw(g);
	textureMode(NORMALIZED); // objmodel fukkaa tämän
	world.draw(g);
	
	for (GameObject obj: coins) obj.draw(g);
	for (GameObject obj: enemies) obj.draw(g);
	
	if (animobj != null) {
		float time = (millis() - animstart) / 1000.0;
		PVector pp = animobj.pos;
		animobj.pos = PVector.add(pp, PVector.mult(animobj.up, 2*time));
		animobj.rot(0.1);
		animobj.draw(g);
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
	mapImage.applyMatrix(mapCam);
	mapImage.translate(-world.size/2, -world.size/2, -world.size/2);
	mapImage.textureMode(NORMALIZED);
	world.draw(mapImage);
	// pelaaja vilkkuu valkoisena, jäljellä olevat rahat punaisia, möröt violetteja
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
	
	// tekstuuriin rendattu juttu vielä näytölle kokeellisesti iteroituun paikkaan
	resetMatrix();
	noLights();
	hint(DISABLE_DEPTH_TEST);
	textureMode(NORMALIZED);
	resetMatrix();
	translate(50, 10, -200);
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

// hudissa debuggidataa ja pelidataa
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

PMatrix3D rotmat(float a, float x, float y, float z) {
	PMatrix3D mat = new PMatrix3D();
	mat.rotate(a, x, y, z);
	return mat;
}

// wsadqe pyörittää karttakuvaa, ja nappi passataan myös pelaajaoliolle
void keyPressed () {
	player.pressKey(key);
	if (key == 'w') mapCam.preApply(rotmat(PI/40, 1, 0, 0));
	if (key == 's') mapCam.preApply(rotmat(-PI/40, 1, 0, 0));
	if (key == 'a') mapCam.preApply(rotmat(-PI/40, 0, 1, 0));
	if (key == 'd') mapCam.preApply(rotmat(PI/40, 0, 1, 0));
	if (key == 'q') mapCam.preApply(rotmat(-PI/40, 0, 0, 1));
	if (key == 'e') mapCam.preApply(rotmat(PI/40, 0, 0, 1));
}

// kartan pyörittäminen hiirellä, copypastaa harkkatehtävästä (omaa koodia silti)

void mousePressed() {
	startDrag(new PVector(mouseX, mouseY));
}
void mouseDragged() {
	drag(new PVector(mouseX, mouseY));
}

PMatrix3D mapCam = new PMatrix3D();
// hiiripyörittelyolio joka muistaa hiiren aloituspaikan
MouseRotation rotation = new MouseRotation();

PMatrix3D lastCamera;
// klikkaa pyöritys alkamaan hiiren nykypisteestä
void startDrag(PVector mouse) {
	lastCamera = new PMatrix3D(mapCam);
	rotation.start(mouse);
}
// laske pyörityskulma ja -akseli, muodosta pyöritysmatriisi,
// kerro pyöritysmatriisilla sijainti joka oli kun hiiri painettiin pohjaan,
// ja sijoita tulos nykykameramatriisiksi
void drag(PVector mouse) {
	float[] rot = new float[4];
	rotation.drag(mouse, rot);
	mapCam.reset();
	mapCam.rotate(3*rot[0], rot[1], rot[2], rot[3]);
	mapCam.apply(lastCamera);
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

