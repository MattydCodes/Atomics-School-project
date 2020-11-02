PGraphics window;
boolean isSimulating = false;
boolean pause = false;


ArrayList<Molecule> Molecules;

void initEnv(){
  window = createGraphics(1000,1000,P2D);
  window.textFont(createFont("Consolas",64));
  Molecules = new ArrayList<Molecule>();
}


PVector randomVec(){
  float r = random(PI*2);
  return new PVector(cos(r),sin(r));
}

void createTempMolecules(){
  for(int i = 0; i < 200; i++){
    Molecules.add(new Molecule(new PVector(random(1000),random(1000)),randomVec(),new Atom(1)));
    Molecules.add(new Molecule(new PVector(random(1000),random(1000)),randomVec(),new Atom(1)));
    Molecules.add(new Molecule(new PVector(random(1000),random(1000)),randomVec(),new Atom(8)));
  }
}


void displaySim(){
  window.beginDraw();
  window.background(255);
  displayMolecules();
  window.endDraw();
  stroke(150);
  strokeWeight(5);
  noFill();
  rect(460,40,1000,1000);
  image(window,460,40,1000,1000);
}

void runSim(){
  updateMolecules();
  collideMolecules();
}
